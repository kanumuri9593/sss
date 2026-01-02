# NFC Tag Registration Feature Documentation

## Overview

The NFC Tag Registration feature allows users to link physical NFC (Near Field Communication) tags to containers in the SSS app. When users tap their phone on a registered NFC tag, the app automatically opens and navigates to the linked container.

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Where to Buy NFC Tags](#where-to-buy-nfc-tags)
3. [Supported NFC Tag Types](#supported-nfc-tag-types)
4. [How to Register NFC Tags](#how-to-register-nfc-tags)
5. [Managing NFC Tags](#managing-nfc-tags)
6. [Troubleshooting](#troubleshooting)
7. [Technical Details](#technical-details)
8. [Error Handling](#error-handling)

---

## Feature Overview

### What You Can Do

- ✅ **Register new NFC tags** - Write your app's deep link to blank NFC stickers
- ✅ **Link to containers** - Associate tags with specific storage containers
- ✅ **View all tags** - See all registered tags in one place
- ✅ **Edit tag information** - Update title, description, and tags
- ✅ **Unlink tags** - Remove the connection between a tag and container
- ✅ **Delete registrations** - Remove tags from the app (physical tag retains data)
- ✅ **QR + NFC together** - Each container can have both a QR code AND an NFC tag

### User Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Create/Edit    │ ──▶ │  Generate QR +  │ ──▶ │  Optionally     │
│  Container      │     │  Deep Link      │     │  Register NFC   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Tap NFC Tag    │ ◀── │  Apply NFC      │ ◀── │  Write to       │
│  to Open        │     │  Sticker        │     │  Physical Tag   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Where to Buy NFC Tags

### Recommended Tag Types

| Tag Type | Memory | Best For | Price Range |
|----------|--------|----------|-------------|
| **NTAG213** | 144 bytes | Simple container links | $0.20-0.50/tag |
| **NTAG215** | 504 bytes | ⭐ Recommended - good balance | $0.30-0.60/tag |
| **NTAG216** | 888 bytes | Detailed descriptions | $0.40-0.80/tag |

### Where to Purchase

#### Amazon (Fastest Shipping)
- Search: "NTAG215 NFC stickers blank"
- Typical pricing: $8-15 for 25-50 tags
- Prime shipping available
- Recommended brands: TimesKey, THONSEN, GoToTags

**Example Search Terms:**
- "NTAG215 NFC stickers 25mm round"
- "Blank NFC tags NTAG213 writable"
- "Waterproof NFC stickers NTAG216"

#### AliExpress (Best Value)
- Much cheaper for bulk orders
- 50-100 tags for $5-15
- Shipping takes 2-4 weeks
- Search: "NTAG215 blank sticker" or "NFC 213 tag"

#### Specialty NFC Stores (Best Quality)

| Store | Website | Notes |
|-------|---------|-------|
| GoToTags | gototags.com | Wide selection, enterprise quality |
| TagStand | tagstand.com | US-based, fast shipping |
| NFCTagify | nfctagify.com | European option |
| Seritag | seritag.com | Custom printing available |
| RapidNFC | rapidnfc.com | UK-based, bulk discounts |

### Tag Format Recommendations

| Use Case | Recommended Format |
|----------|-------------------|
| Boxes/Containers | 25-30mm round stickers |
| Shelves/Racks | Rectangle stickers (50x25mm) |
| Kitchen/Bathroom | Waterproof epoxy tags |
| Metal surfaces | Anti-metal NFC tags (required!) |
| Key chains | NFC keyfob or coin tags |

### Important Notes

⚠️ **Anti-Metal Tags**: Regular NFC stickers DO NOT work on metal surfaces. If attaching to metal containers, you MUST buy special "anti-metal" or "on-metal" NFC tags.

⚠️ **Avoid MIFARE Tags**: Some cheap NFC tags use MIFARE Classic technology which is NOT compatible with iPhone. Always ensure tags say "NTAG" or "NFC Forum Type 2".

---

## Supported NFC Tag Types

### Compatible Tags (Recommended)

| Standard | Tag Types | iOS Support | Android Support |
|----------|-----------|-------------|-----------------|
| NFC Forum Type 2 | NTAG213, NTAG215, NTAG216 | ✅ Full | ✅ Full |
| NFC Forum Type 4 | NTAG424 | ✅ Full | ✅ Full |
| ISO 14443-3A | Generic Type A | ✅ Read/Write | ✅ Read/Write |

### Incompatible Tags (Avoid)

| Tag Type | Why It Won't Work |
|----------|-------------------|
| MIFARE Classic | Not supported by iPhone |
| MIFARE DESFire | Requires special keys |
| ISO 15693 | Limited iOS support |
| Felica | Japan-only standard |

---

## How to Register NFC Tags

### Method 1: During Container Creation

1. **Create a new container**
   - Tap the + button on the main screen
   - Fill in container name, type, and description
   - Add a photo (optional)
   - Tap "Create Container"

2. **After creation, scroll down to NFC section**
   - You'll see "NFC Tag (Optional)" section
   - Tap "Register NFC Tag"

3. **Fill in tag details**
   - Title: A name for the tag (e.g., "Winter Box Label")
   - Description: What's in the container
   - Tags: Keywords for searching

4. **Write to the physical tag**
   - Tap "Write & Register Tag"
   - Hold your phone near the NFC sticker:
     - **iPhone**: Position TOP of phone near the tag
     - **Android**: Position BACK/CENTER of phone near the tag
   - Keep steady for 2-3 seconds

5. **Done!**
   - The tag is now linked to your container
   - Apply the sticker to your container

### Method 2: From Container Details

1. **Open an existing container**
2. **Tap the NFC icon** in the top toolbar
3. **Select "Register & Link NFC Tag"**
4. **Follow steps 3-5 above**

### Method 3: NFC Tag Management Screen

1. **Go to Settings → NFC Tag Management** (or access from container)
2. **Tap "Register New Tag"**
3. **Choose whether to link to a container**
4. **Follow the registration flow**

---

## Managing NFC Tags

### View All Registered Tags

1. Access NFC Tag Management from:
   - Container detail screen → NFC icon
   - Settings → NFC Tags

2. See all your registered tags with:
   - Title and description
   - Linked container (if any)
   - Tag ID and status

### Edit a Tag

1. Find the tag in the list
2. Tap on it or select "Edit" from the menu
3. Update:
   - Title
   - Description
   - Tags/keywords
4. Optional: Check "Rewrite Physical Tag" to update the sticker too
5. Tap "Save Changes"

### Link Tag to Different Container

1. Find the tag in the list
2. Select "Unlink" from the menu (if already linked)
3. Select "Link to Container"
4. Choose the new container

### Unlink Tag from Container

1. Open the container detail screen
2. Tap the NFC icon
3. Select "Unlink NFC Tag"
4. Confirm the action

The tag remains registered but is no longer associated with any container.

### Delete a Tag Registration

1. Find the tag in the list
2. Select "Delete" from the menu
3. Confirm deletion

**Note:** This only removes the tag from the app database. The physical NFC sticker still contains data. To completely erase a tag, you would need to:
- Register it again with blank/placeholder data, OR
- Use a third-party NFC app to format it

---

## Troubleshooting

### "NFC Not Available" Error

**iOS:**
1. Go to Settings > General > NFC
2. Make sure "NFC Tag Reading" is ON
3. Requires iPhone 7 or newer
4. Some features require iOS 13+

**Android:**
1. Go to Settings > Connected devices > Connection preferences > NFC
2. Toggle NFC ON
3. On some phones: Settings > More > NFC

### "Write Failed" Error

| Cause | Solution |
|-------|----------|
| Tag already locked | Use a different, blank tag |
| Tag damaged | Try a new tag |
| Wrong tag type (MIFARE) | Use NTAG tags only |
| Tag on metal surface | Use anti-metal tags |
| Data too large | Use NTAG215/216 for more space |

### "Tag Not Detected" Error

**iPhone Tips:**
- NFC reader is at the TOP of the phone
- Remove thick phone cases
- Hold phone 1-2cm from tag
- Move slowly, don't just tap

**Android Tips:**
- NFC reader is usually in the CENTER-BACK
- Check your phone's NFC antenna location
- Remove metal cases
- Enable NFC in settings first

### Tag Works But Opens Wrong App

The tag may contain data from another app. Solutions:
1. Re-register the tag with SSS app (overwrites old data)
2. Use a fresh, blank tag
3. Format the tag with an NFC tool app first

### Tag Shows "Unknown Format"

1. The tag wasn't written by SSS app
2. Solutions:
   - Register it as a new tag (will overwrite)
   - Format the tag first with NFC Tools app

---

## Technical Details

### Deep Link Format

NFC tags are written with deep links in this format:
```
sss://nfc/{registration-id}
```

When scanned, the system:
1. Recognizes the `sss://` scheme
2. Routes to the SSS app
3. Looks up the registration ID
4. Navigates to the linked container

### Data Structure

Each NFC tag registration stores:

```json
{
  "id": "nfc-1234567890-abc123",
  "tagId": "04:A2:B3:C4:D5:E6:F7",
  "containerId": "container-1234567890-xyz",
  "containerName": "Winter Clothes Box",
  "title": "Winter Box Label",
  "description": "Contains winter coats, sweaters",
  "tags": ["winter", "clothes", "garage"],
  "deepLink": "sss://nfc/nfc-1234567890-abc123",
  "createdAt": "2025-01-02T10:30:00Z",
  "lastModified": "2025-01-02T11:45:00Z",
  "status": "active"
}
```

### Storage

- Tags are stored locally using Hive database
- Data persists across app restarts
- Physical tag ID (UID) is captured for identification

### Security Considerations

- Tags can be read by any NFC-enabled phone
- Deep links only work if SSS app is installed
- No sensitive data is stored on the physical tag
- Only the deep link URL is written to the tag

---

## Error Handling

### Common Errors and Recovery

| Error | Cause | Auto-Recovery | User Action |
|-------|-------|---------------|-------------|
| NFC Disabled | Device NFC off | Prompt shown | Enable in Settings |
| Write Timeout | Tag moved | Retry prompt | Hold steady, try again |
| Tag Locked | Read-only tag | N/A | Use different tag |
| Session Error | iOS session issue | Auto-retry | Wait and try again |
| Tag Already Registered | Duplicate UID | Warning shown | Edit existing or use new tag |

### Error Messages Reference

| Message | Meaning | Solution |
|---------|---------|----------|
| "NFC is not enabled" | Device NFC is off | Turn on NFC in Settings |
| "This tag is already registered" | Tag UID exists in database | Edit existing registration |
| "Failed to write to tag" | Write operation failed | Check tag type, try again |
| "Session timed out" | No tag detected in 60s | Retry, position phone correctly |
| "Tag is not writable" | Tag is locked or read-only | Use a different tag |

---

## Best Practices

### Organizing Your Tags

1. **Label your tags** before applying
   - Write container name on the back
   - Use different colors for different rooms

2. **Position tags consistently**
   - Same corner on all boxes
   - Visible but not in the way

3. **Keep backup of registrations**
   - Take screenshots of your tag list
   - Note which tags go with which containers

### Maintenance

1. **Periodically check tags**
   - Make sure they still work
   - Replace damaged stickers

2. **Update descriptions**
   - When contents change, update the tag info
   - Keeps search accurate

3. **Clean unused registrations**
   - Delete tags for containers you no longer have
   - Keeps your list manageable

---

## FAQ

**Q: Can I use the same tag for multiple containers?**
A: No, each physical tag has a unique ID and can only be linked to one container at a time.

**Q: What happens if I lose the physical tag?**
A: You can delete the registration from the app. The container and its QR code are unaffected.

**Q: Can someone else scan my tags?**
A: Yes, but they would need the SSS app installed. The deep link only contains an ID, not sensitive data.

**Q: Do tags need batteries?**
A: No, NFC tags are passive and powered by the scanning phone.

**Q: How long do NFC stickers last?**
A: High-quality tags last 10+ years. They can be read/written 100,000+ times.

**Q: Can I use NFC without QR codes?**
A: Yes! NFC and QR are independent. You can use either or both.

---

## Support

If you encounter issues not covered here:

1. Check the "Help" tab in NFC Tag Management
2. Review the troubleshooting section above
3. Try with a fresh, new NFC tag
4. Ensure your device supports NFC

---

*Last updated: January 2, 2025*
