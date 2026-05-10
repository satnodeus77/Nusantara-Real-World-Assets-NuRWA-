from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="NuRWA API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


projects_db =[
    {
        "id": "umkm_01", "name": "Kedai Kopi Senja",
        "description": "Ekspansi kapasitas roasting kopi lokal untuk memenuhi permintaan ekspor internasional.",
        "funding_goal_usdc": 500, "funded_usdc": 300, "apy_percent": 12.5, "days_remaining": 14,
        "location": "Yogyakarta", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?q=80&w=500&auto=format&fit=crop"
    },
    {
        "id": "umkm_02", "name": "Bakmi Jawa Sleman",
        "description": "Pembelian mesin pembuat mie otomatis untuk pembukaan cabang kedua di area Sleman.",
        "funding_goal_usdc": 1000, "funded_usdc": 1000, "apy_percent": 14.0, "days_remaining": 5,
        "location": "Sleman", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1617093727343-374698b1b08d?q=80&w=500&auto=format&fit=crop"
    },
    {   # THIS PROJECT IS EXPIRED & UNDERFUNDED (Will trigger Escrow Refund Demo)
        "id": "umkm_03", "name": "Pengrajin Batik Bantul",
        "description": "Modal kerja pengadaan bahan baku kain sutra dan pewarna alami ramah lingkungan.",
        "funding_goal_usdc": 2000, "funded_usdc": 400, "apy_percent": 15.2, "days_remaining": 0,
        "location": "Bantul", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1604973104381-870c92f10343?q=80&w=1170&auto=format&fit=crop"
    },
    {
        "id": "umkm_04", "name": "Tambak Udang Vaname",
        "description": "Peningkatan teknologi aerator tenaga surya untuk tambak udang di pesisir selatan.",
        "funding_goal_usdc": 5000, "funded_usdc": 1250, "apy_percent": 18.0, "days_remaining": 21,
        "location": "Kulon Progo", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1689380631113-6d52dc6008b7?q=80&w=1170&auto=format&fit=crop"
    },
    {
        "id": "umkm_05", "name": "Konveksi Hijab Modis",
        "description": "Penambahan 5 mesin jahit industri untuk memenuhi lonjakan pesanan bulan Ramadhan.",
        "funding_goal_usdc": 1500, "funded_usdc": 900, "apy_percent": 13.5, "days_remaining": 10,
        "location": "Bandung", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1466027397211-20d0f2449a3f?q=80&w=1118&auto=format&fit=crop"
    },
    {
        "id": "umkm_06", "name": "Roastery Biji Nusantara",
        "description": "Sertifikasi organik dan perizinan ekspor biji kopi Arabika ke pasar Eropa.",
        "funding_goal_usdc": 3000, "funded_usdc": 2100, "apy_percent": 11.8, "days_remaining": 30,
        "location": "Jakarta", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://images.unsplash.com/photo-1585435247026-1d8560423d52?q=80&w=1170&auto=format&fit=crop"
    },
    {
        "id": "umkm_07", "name": "Bengkel EV Konversi",
        "description": "Pengadaan sparepart baterai lithium untuk konversi 50 motor bensin menjadi motor listrik.",
        "funding_goal_usdc": 4000, "funded_usdc": 500, "apy_percent": 16.5, "days_remaining": 7,
        "location": "Surabaya", "umkm_wallet_address": "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548",
        "image_url": "https://plus.unsplash.com/premium_photo-1715639312136-56a01f236440?q=80&w=1157&auto=format&fit=crop"
    }
]


user_investments =[] 
user_yields = {} # Dict: {"wallet": {"unclaimed": 0.0, "lifetime": 0.0}}

class LoginRequest(BaseModel):
    wallet_address: str

class InvestRequest(BaseModel):
    wallet_address: str
    umkm_id: str
    umkm_name: str
    amount_usdc: float
    tx_hash: str

class OracleYieldRequest(BaseModel):
    umkm_id: str
    revenue_fiat: float

class RefundRequest(BaseModel):
    wallet_address: str
    umkm_id: str

@app.post("/api/auth/login")
def login_user(req: LoginRequest):
    
    existing =[inv for inv in user_investments if inv["wallet"] == req.wallet_address and inv["umkm_id"] == "umkm_03"]
    if not existing:
        user_investments.append({
            "wallet": req.wallet_address,
            "umkm_id": "umkm_03",
            "umkm_name": "Pengrajin Batik Bantul",
            "amount_usdc": 50.0,
            "tokens": 500.0
        })
        

        if req.wallet_address not in user_yields:
            user_yields[req.wallet_address] = {"unclaimed": 0.0, "lifetime": 0.0}

    return {"status": "success", "wallet": req.wallet_address}

@app.get("/api/projects")
def get_marketplace_projects():
    return projects_db

@app.post("/api/invest")
def record_investment(req: InvestRequest):
    tokens_minted = req.amount_usdc * 10 
    
    user_investments.append({
        "wallet": req.wallet_address,
        "umkm_id": req.umkm_id,
        "umkm_name": req.umkm_name,
        "amount_usdc": req.amount_usdc,
        "tokens": tokens_minted
    })
    

    for p in projects_db:
        if p["id"] == req.umkm_id:
            p["funded_usdc"] += req.amount_usdc

    if req.wallet_address not in user_yields:
        user_yields[req.wallet_address] = {"unclaimed": 0.0, "lifetime": 0.0}
        
    return {"status": "success", "message": f"Recorded {tokens_minted} RST"}

@app.get("/api/portfolio/{wallet_address}")
def get_portfolio(wallet_address: str):

    user_assets =[]
    total_balance = 0.0
    
    for inv in user_investments:
        if inv["wallet"] == wallet_address:

            project = next((p for p in projects_db if p["id"] == inv["umkm_id"]), None)
            is_refundable = False
            if project:
                is_expired = project["days_remaining"] <= 0
                is_underfunded = project["funded_usdc"] < project["funding_goal_usdc"]
                is_refundable = is_expired and is_underfunded

            user_assets.append({
                **inv,
                "is_refundable": is_refundable
            })
            total_balance += inv["amount_usdc"]

    yield_data = user_yields.get(wallet_address, {"unclaimed": 0.0, "lifetime": 0.0})
    
    return {
        "total_balance_usdc": total_balance,
        "unclaimed_yield_usdc": yield_data["unclaimed"],
        "lifetime_yield_usdc": yield_data["lifetime"],
        "assets": user_assets
    }

@app.post("/api/oracle/distribute-yield")
def oracle_trigger_yield(req: OracleYieldRequest):
    umkm_investors = [inv for inv in user_investments if inv["umkm_id"] == req.umkm_id]
    if not umkm_investors:
        return {"message": "No investors found."}
    
    total_funded_for_umkm = sum(inv["amount_usdc"] for inv in umkm_investors)
    yield_pool = req.revenue_fiat * 0.10 
    
    for inv in umkm_investors:
        user_share_percentage = inv["amount_usdc"] / total_funded_for_umkm
        user_yield = yield_pool * user_share_percentage
        
        if inv["wallet"] not in user_yields:
            user_yields[inv["wallet"]] = {"unclaimed": 0.0, "lifetime": 0.0}
            
        user_yields[inv["wallet"]]["unclaimed"] += user_yield
        user_yields[inv["wallet"]]["lifetime"] += user_yield 
        
    return {"status": "success", "distributed_pool": yield_pool}

@app.post("/api/claim-yield")
def claim_yield(req: LoginRequest):
    yield_data = user_yields.get(req.wallet_address, {"unclaimed": 0.0, "lifetime": 0.0})
    claimed_amount = yield_data["unclaimed"]
    user_yields[req.wallet_address]["unclaimed"] = 0.0
    return {"status": "success", "claimed": claimed_amount}

@app.post("/api/refund")
def trigger_escrow_refund(req: RefundRequest):
    """Simulates Escrow Vault returning funds to user if campaign fails."""
    global user_investments
    refund_amount = 0.0
    
    # Extract and remove the investment
    remaining_investments =[]
    for inv in user_investments:
        if inv["wallet"] == req.wallet_address and inv["umkm_id"] == req.umkm_id:
            refund_amount += inv["amount_usdc"]
        else:
            remaining_investments.append(inv)
            
    user_investments = remaining_investments
    
  
    for p in projects_db:
        if p["id"] == req.umkm_id:
            p["funded_usdc"] -= refund_amount
            
    return {"status": "success", "refunded_amount": refund_amount}