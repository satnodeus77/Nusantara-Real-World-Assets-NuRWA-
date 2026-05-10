import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { NurwaCore } from "../target/types/nurwa_core";
import { createMint, getOrCreateAssociatedTokenAccount, TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { expect } from "chai";

describe("nu_rwa_marketplace", () => {
  anchor.setProvider(anchor.AnchorProvider.env());
  const provider = anchor.getProvider();
  const program = anchor.workspace.NurwaCore as Program<NurwaCore>;

  const buyer = anchor.web3.Keypair.generate();

  it("Executes an automated UMKM share purchase!", async () => {
    const assetName = "Warung Kopi Jogja";
    const [assetPda] = anchor.web3.PublicKey.findProgramAddressSync([Buffer.from("asset"), provider.publicKey.toBuffer(), Buffer.from(assetName)],
      program.programId
    );

    // 1. Airdrop testing SOL to our fake buyer
    const signature = await provider.connection.requestAirdrop(buyer.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.confirmTransaction(signature);

    // 2. Register UMKM
    await program.methods
      .registerAsset(assetName, { realEstate: {} }, new anchor.BN(500000))
      .accounts({ asset: assetPda, owner: provider.publicKey })
      .rpc();
    
    // 3. Create Mint (Set the Smart Contract PDA as the Authority!)
    const mint = await createMint(
      provider.connection, 
      (provider.wallet as any).payer, 
      assetPda, // <--- PDA controls the tokens!
      null, 
      0
    );
    
    // 4. List shares for sale
    const pricePerShare = new anchor.BN(1000000); 
    await program.methods
      .listShares(pricePerShare)
      .accounts({ asset: assetPda, owner: provider.publicKey })
      .rpc();

    // 5. Buyer purchases 100 shares 
    const buyerAta = await getOrCreateAssociatedTokenAccount(
      provider.connection, 
      buyer, 
      mint, 
      buyer.publicKey
    );
    
    await program.methods
      .purchaseShares(new anchor.BN(100))
      .accounts({
        asset: assetPda,
        ownerMainAccount: provider.publicKey,
        shareMint: mint,
        buyer: buyer.publicKey,
        buyerTokenAccount: buyerAta.address,
        tokenProgram: TOKEN_PROGRAM_ID,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([buyer])
      .rpc();

    const buyerTokenBalance = await provider.connection.getTokenAccountBalance(buyerAta.address);
    console.log(" SUCCESS! Buyer now holds:", buyerTokenBalance.value.uiAmount, "UMKM shares!");
    expect(Number(buyerTokenBalance.value.amount)).to.equal(100);
  });
});