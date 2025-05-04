<div style="max-width: 800px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif; line-height: 1.6; color: #2c3e50;">

<h1 style="text-align: center; color: #1a237e; font-size: 2.5em; margin-bottom: 20px; background: linear-gradient(45deg, #1a237e, #4a148c); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">
📖 Centuari Protocol
</h1>

<div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 30px;">
<p style="font-size: 1.1em; margin: 0;">Welcome to Centuari, an innovative decentralized lending protocol powered by a deCentralized Lending Order Book (CLOB) system. Centuari enables both retail and institutional users to access fixed-rate loans, either with or without collateral, secured by a restaking-based underwriting system.</p>
</div>

<h2 style="color: #1a237e; border-left: 4px solid #1a237e; padding-left: 10px; margin-top: 30px;">📌 Overview</h2>
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin: 20px 0;">
<div style="background: #f8f9fa; padding: 15px; border-radius: 8px;">
<strong>📝 CLOB-based lending market</strong><br>
<strong>💸 Tokenized bond system</strong><br>
<strong>🛡️ Restaking underwriting</strong><br>
<strong>📊 Yield-optimizing vaults</strong>
</div>
</div>

<h2 style="color: #1a237e; border-left: 4px solid #1a237e; padding-left: 10px;">📂 Project Structure</h2>
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin: 20px 0;">

<div style="background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; padding: 15px;">
<h3 style="margin-top: 0; color: #1a237e;">1️⃣ Centuari CLOB</h3>
<p>Decentralized lending marketplace using Central Limit Order Book model</p>
<div style="background: #f8f9fa; padding: 10px; border-radius: 6px; margin: 10px 0;">
<pre style="margin: 0; font-size: 0.9em;">
function matchOrders(Id marketId, uint256 maxMatchCount) external onlyOwner {
  MarketConfig storage market = CentuariCLOBDSLib.getMarket(marketId);
  OrderQueueLib.matchOrders(
    market.orderQueue,
    market.priceTickSize,
    maxMatchCount
  );
}</pre>
</div>
</div>

</div>

<h2 style="color: #1a237e; border-left: 4px solid #1a237e; padding-left: 10px;">⚙️ Key Components</h2>
<table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
<tr style="background: #1a237e; color: white;">
<th style="padding: 12px; text-align: left;">📦 Module</th>
<th style="padding: 12px; text-align: left;">📖 Description</th>
</tr>
<tr style="border-bottom: 1px solid #e0e0e0;">
<td style="padding: 12px;">CLOB Engine</td>
<td>On-chain decentralized matching engine</td>
</tr>
</table>

<h2 style="color: #1a237e; border-left: 4px solid #1a237e; padding-left: 10px;">🛠 Tech Stack</h2>
<div style="display: flex; gap: 10px; flex-wrap: wrap;">
<span style="background: #4a148c; color: white; padding: 6px 12px; border-radius: 20px; font-size: 0.9em;">Solidity</span>
<span style="background: #4a148c; color: white; padding: 6px 12px; border-radius: 20px; font-size: 0.9em;">Foundry</span>
</div>

<h2 style="color: #1a237e; border-left: 4px solid #1a237e; padding-left: 10px;">🤝 Contribute & Connect</h2>
<div style="display: flex; gap: 15px; margin: 20px 0;">
<a href="https://x.com/CentuariLabs" style="background: #1da1f2; color: white; padding: 10px 20px; border-radius: 5px; text-decoration: none;">🐦 Twitter</a>
<a href="https://discord.gg/XU2hUG4Uuz" style="background: #5865f2; color: white; padding: 10px 20px; border-radius: 5px; text-decoration: none;">💬 Discord</a>
</div>

<div style="margin-top: 40px; padding: 20px; background: #f8f9fa; border-radius: 8px; text-align: center;">
📜 License: Licensed under the MIT License
</div>

</div>
