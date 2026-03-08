#!/usr/bin/env python3
"""
Build InnerFresh Operating System wireframes in Penpot
Uses Penpot HTTP API to create design structure
"""

import requests
import json
import os
from datetime import datetime

# Load config
config = {}
config_path = os.path.expanduser('~/.openclaw/workspace/.penpot-config')
with open(config_path) as f:
    for line in f:
        key, value = line.strip().split('=')
        config[key] = value

API_KEY = config['PENPOT_API_KEY']
TEAM_ID = config['PENPOT_TEAM_ID']
FILE_ID = config['PENPOT_FILE_ID']
PAGE_ID = config['PENPOT_PAGE_ID']

# Penpot API endpoint
API_BASE = "https://penpot.app/api/rpc/command/v1"

def penpot_api_call(method, params):
    """Make authenticated API call to Penpot"""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    payload = {
        "method": method,
        "params": params
    }
    
    try:
        response = requests.post(API_BASE, json=payload, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"❌ API Error: {e}")
        return None

def create_frame(name, x, y, width, height):
    """Create a frame in Penpot"""
    params = {
        "file-id": FILE_ID,
        "page-id": PAGE_ID,
        "name": name,
        "x": x,
        "y": y,
        "width": width,
        "height": height
    }
    print(f"📐 Creating frame: {name}")
    return penpot_api_call("create/frame", params)

def create_text(frame_id, name, content, x, y, width, height, font_size=16, font_weight="normal"):
    """Create a text element"""
    params = {
        "frame-id": frame_id,
        "name": name,
        "content": content,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "font-size": font_size,
        "font-weight": font_weight
    }
    return penpot_api_call("create/text", params)

def create_rectangle(frame_id, name, x, y, width, height, fill_color="#FFFFFF"):
    """Create a rectangle shape"""
    params = {
        "frame-id": frame_id,
        "name": name,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "fill-color": fill_color
    }
    return penpot_api_call("create/rect", params)

print("""
╔════════════════════════════════════════════════════════════════╗
║  InnerFresh Operating System — Penpot Wireframe Builder       ║
║  Building 6 main tabs + layouts                               ║
╚════════════════════════════════════════════════════════════════╝
""")

# Create 6 main tab frames
frames = [
    {"name": "1. Creative Intelligence Dashboard", "x": 0, "y": 0},
    {"name": "2. Pages & Angles", "x": 1600, "y": 0},
    {"name": "3. Meta Winners Hub", "x": 3200, "y": 0},
    {"name": "4. Brand Intelligence", "x": 0, "y": 900},
    {"name": "5. Content Factory", "x": 1600, "y": 900},
    {"name": "6. Distribution & Channels", "x": 3200, "y": 900},
]

print("\n✨ Creating 6 main tab frames...")

for tab in frames:
    frame = create_frame(
        name=tab["name"],
        x=tab["x"],
        y=tab["y"],
        width=1500,
        height=800
    )
    if frame:
        frame_id = frame.get('result', {}).get('id')
        print(f"  ✅ {tab['name']} (ID: {frame_id})")
        
        # Add placeholder content to each frame
        if "Creative Intelligence" in tab["name"]:
            create_text(frame_id, "Title", "Creative Intelligence Dashboard", 20, 20, 400, 40, 28, "bold")
            create_rectangle(frame_id, "Data Table", 20, 80, 1460, 680, "#F3F4F6")
            create_text(frame_id, "Note", "Performance matrix with tags, filters, recommendations", 20, 90, 400, 20, 12)
            
        elif "Pages & Angles" in tab["name"]:
            create_text(frame_id, "Title", "Pages & Angles Overview", 20, 20, 400, 40, 28, "bold")
            create_rectangle(frame_id, "Authority Pages", 20, 80, 720, 340, "#EFF6FF")
            create_rectangle(frame_id, "Community Pages", 760, 80, 720, 340, "#F0FDF4")
            create_rectangle(frame_id, "Recommendations", 20, 440, 1460, 220, "#FEF3C7")
            
        elif "Meta Winners" in tab["name"]:
            create_text(frame_id, "Title", "Meta Winners Hub", 20, 20, 400, 40, 28, "bold")
            create_rectangle(frame_id, "Top Performers", 20, 80, 720, 680, "#DBEAFE")
            create_rectangle(frame_id, "Action Queue", 760, 80, 720, 680, "#FECACA")
            
        elif "Brand Intelligence" in tab["name"]:
            create_text(frame_id, "Title", "Brand Intelligence - Org & Operations", 20, 20, 500, 40, 28, "bold")
            create_rectangle(frame_id, "Org Chart", 20, 80, 480, 340, "#F3E8FF")
            create_rectangle(frame_id, "Dependencies", 520, 80, 480, 340, "#FCE7F3")
            create_rectangle(frame_id, "Automations", 1020, 80, 460, 340, "#E0E7FF")
            
        elif "Content Factory" in tab["name"]:
            create_text(frame_id, "Title", "Content Factory Pipeline", 20, 20, 400, 40, 28, "bold")
            create_rectangle(frame_id, "Production Queue", 20, 80, 1460, 340, "#F0F9FF")
            create_rectangle(frame_id, "30-Day Calendar", 20, 440, 1460, 220, "#ECFDF5")
            
        elif "Distribution" in tab["name"]:
            create_text(frame_id, "Title", "Distribution & Growth Channels", 20, 20, 500, 40, 28, "bold")
            create_rectangle(frame_id, "Paid Channels", 20, 80, 720, 340, "#FEF3C7")
            create_rectangle(frame_id, "Owned Channels", 760, 80, 720, 340, "#D1FAE5")
            create_rectangle(frame_id, "Checkout Options", 20, 440, 1460, 220, "#FEE2E2")

print("\n✨ Creating navigation bar...")
nav_frame = create_frame(
    name="Navigation",
    x=0,
    y=1800,
    width=4800,
    height=80
)

print("\n" + "="*60)
print("✅ Wireframe structure created in Penpot!")
print("="*60)
print("\n📊 Next steps:")
print("  1. Open: https://design.penpot.app/#/workspace")
print("  2. Your designer refines each tab")
print("  3. I spawn Codex to build the actual platform")
print("\n💡 Each tab has:")
print("  - Title & layout sections")
print("  - Color-coded areas (blue for data, green for metrics, etc)")
print("  - Placeholder areas for your designer to detail")
print("\n🦞 Ready for Codex build whenever you approve the design.")
