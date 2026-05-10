use anchor_lang::prelude::*;
use anchor_lang::solana_program::system_instruction;
use anchor_spl::token::{self, Mint, Token, TokenAccount, MintTo};


declare_id!("J1cVKBkzkP9PKuiA2rLJGZsF3ppJ794mA9km7Eo4wuFd");

#[program]
pub mod nurwa_core {
    use super::*;

    pub fn register_asset(ctx: Context<RegisterAsset>, name: String, asset_class: AssetClass, value: u64) -> Result<()> {
        let asset = &mut ctx.accounts.asset;
        asset.owner = *ctx.accounts.owner.key;
        asset.name = name;
        asset.asset_class = asset_class;
        asset.value = value;
        asset.price_per_share = 0;
        asset.shares_sold = 0;
        asset.bump = ctx.bumps.asset; // Store the PDA bump for later
        Ok(())
    }

    pub fn list_shares(ctx: Context<ListShares>, price: u64) -> Result<()> {
        let asset = &mut ctx.accounts.asset;
        require_keys_eq!(asset.owner, ctx.accounts.owner.key(), NurwaError::Unauthorized);
        asset.price_per_share = price;
        msg!("Asset {} shares listed at {} lamports each", asset.name, price);
        Ok(())
    }

    // Automated ICO Dispenser: No UMKM Owner signature required here
    pub fn purchase_shares(ctx: Context<PurchaseShares>, amount: u64) -> Result<()> {
        let asset = &mut ctx.accounts.asset;
        let total_cost = asset.price_per_share.checked_mul(amount).unwrap();

        // Prevent minting more than 1,000,000 shares
        require!(asset.shares_sold + amount <= 1_000_000, NurwaError::SoldOut);

        // 1. Send SOL from Buyer directly to UMKM Owner
        let transfer_sol_ix = system_instruction::transfer(
            &ctx.accounts.buyer.key(),
            &asset.owner,
            total_cost,
        );
        anchor_lang::solana_program::program::invoke(
            &transfer_sol_ix,
            &[
                ctx.accounts.buyer.to_account_info(),
                ctx.accounts.owner_main_account.to_account_info(),
                ctx.accounts.system_program.to_account_info(),
            ],
        )?;

        // 2. The Smart Contract signs the token minting
        let asset_name_bytes = asset.name.as_bytes();
        let owner_key = asset.owner;
        let bump = asset.bump;
        let seeds = &[
            b"asset",
            owner_key.as_ref(),
            asset_name_bytes,
            &[bump],
        ];
        let signer = &[&seeds[..]];

        let cpi_accounts = MintTo {
            mint: ctx.accounts.share_mint.to_account_info(),
            to: ctx.accounts.buyer_token_account.to_account_info(),
            authority: asset.to_account_info(), // The PDA is the authority!
        };
        token::mint_to(
            CpiContext::new_with_signer(ctx.accounts.token_program.to_account_info(), cpi_accounts, signer),
            amount,
        )?;

        asset.shares_sold += amount;
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(name: String)]
pub struct RegisterAsset<'info> {
    #[account(
        init, 
        payer = owner, 
        space = 8 + 300, 
        seeds = [b"asset", owner.key().as_ref(), name.as_bytes()], 
        bump
    )]
    pub asset: Account<'info, Asset>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ListShares<'info> {
    #[account(mut)]
    pub asset: Account<'info, Asset>,
    pub owner: Signer<'info>,
}

#[derive(Accounts)]
pub struct PurchaseShares<'info> {
    #[account(mut)]
    pub asset: Account<'info, Asset>,
    /// CHECK: We are just sending SOL to this account. It's safe.
    #[account(mut, address = asset.owner)]
    pub owner_main_account: AccountInfo<'info>,
    #[account(mut)]
    pub share_mint: Account<'info, Mint>,
    #[account(mut)]
    pub buyer: Signer<'info>,
    #[account(mut)]
    pub buyer_token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct Asset {
    pub owner: Pubkey,
    pub name: String,
    pub asset_class: AssetClass,
    pub value: u64,
    pub price_per_share: u64,
    pub shares_sold: u64,
    pub bump: u8, // Stores the PDA seed bump
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum AssetClass { RealEstate, Vehicle, Invoice }

#[error_code]
pub enum NurwaError {
    #[msg("Unauthorized access.")] Unauthorized,
    #[msg("Not enough shares remaining.")] SoldOut,
}