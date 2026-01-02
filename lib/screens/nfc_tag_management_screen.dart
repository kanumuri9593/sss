import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/nfc_tag_storage_service.dart';
import '../services/container_service.dart';
import '../models/container.dart' as models;
import 'container_detail_screen.dart';

/// Comprehensive NFC Tag Management Screen
///
/// Provides full CRUD operations for NFC tags:
/// - Register new tags (scan and write)
/// - View all registered tags
/// - Modify tag data
/// - Delete/unlink tags
/// - Link tags to containers
class NFCTagManagementScreen extends StatefulWidget {
  /// Optional container ID to link the tag to
  final String? containerId;

  /// If true, returns after successful tag registration (for integration with container creation)
  final bool returnOnSuccess;

  const NFCTagManagementScreen({
    super.key,
    this.containerId,
    this.returnOnSuccess = false,
  });

  @override
  State<NFCTagManagementScreen> createState() => _NFCTagManagementScreenState();
}

class _NFCTagManagementScreenState extends State<NFCTagManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NFCTagStoredRegistration> _tags = [];
  bool _isLoading = true;
  bool _isNFCAvailable = false;
  String? _nfcStatusMessage;
  models.Container? _linkedContainer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      // Initialize NFC tag storage
      await NFCTagStorageService.initialize();

      // Check NFC availability
      _isNFCAvailable = await NFCService.isNFCAvailable();
      if (!_isNFCAvailable) {
        final status = await NFCService.getNFCAvailabilityStatus();
        _nfcStatusMessage = _getNFCStatusMessage(status);
      }

      // Load linked container if provided
      if (widget.containerId != null) {
        _linkedContainer = ContainerService.getContainer(widget.containerId!);
      }

      // Load all tags
      _loadTags();
    } catch (e) {
      debugPrint('[NFCManagement] Error initializing: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getNFCStatusMessage(dynamic status) {
    switch (status.toString()) {
      case 'NfcAvailability.disabled':
        return 'NFC is disabled. Please enable NFC in your device Settings.';
      case 'NfcAvailability.unsupported':
        return 'This device does not support NFC.';
      default:
        return 'NFC is not available.';
    }
  }

  void _loadTags() {
    final allTags = NFCTagStorageService.getAllTags();

    // If we have a container ID, filter to show linked tags first
    if (widget.containerId != null) {
      final linkedTags = allTags
          .where((t) => t.containerId == widget.containerId)
          .toList();
      final otherTags = allTags
          .where((t) => t.containerId != widget.containerId)
          .toList();
      _tags = [...linkedTags, ...otherTags];
    } else {
      _tags = allTags;
    }

    if (mounted) setState(() {});
  }

  Future<void> _registerNewTag() async {
    if (!_isNFCAvailable) {
      _showNFCDisabledDialog();
      return;
    }

    final result = await Navigator.push<NFCTagStoredRegistration?>(
      context,
      MaterialPageRoute(
        builder: (context) => _NFCTagRegisterDialog(
          containerId: widget.containerId,
          containerName: _linkedContainer?.name,
        ),
      ),
    );

    if (result != null) {
      _loadTags();
      if (widget.returnOnSuccess && mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  Future<void> _editTag(NFCTagStoredRegistration tag) async {
    final result = await Navigator.push<NFCTagStoredRegistration?>(
      context,
      MaterialPageRoute(builder: (context) => _NFCTagEditScreen(tag: tag)),
    );

    if (result != null) {
      _loadTags();
    }
  }

  Future<void> _deleteTag(NFCTagStoredRegistration tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete NFC Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${tag.title}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will only remove the tag from the app. '
                      'The physical NFC tag will retain its data.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await NFCTagStorageService.deleteTag(tag.id);
      if (success) {
        // Also unlink from container if linked
        if (tag.containerId != null) {
          await ContainerService.unlinkNFCTag(tag.containerId!);
        }
        _loadTags();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('NFC tag deleted')));
        }
      }
    }
  }

  Future<void> _linkToContainer(NFCTagStoredRegistration tag) async {
    final containers = ContainerService.getAllContainers();

    if (containers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No containers available. Create a container first.'),
        ),
      );
      return;
    }

    final selected = await showDialog<models.Container>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Link to Container'),
        children: containers.map((container) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, container),
            child: ListTile(
              leading: Text(
                container.typeIcon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(container.name),
              subtitle: Text(container.typeDisplayName),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await NFCTagStorageService.linkTagToContainer(
        tag.id,
        selected.id,
        selected.name,
      );
      await ContainerService.linkNFCTag(selected.id, tag.tagId);
      _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag linked to "${selected.name}"')),
        );
      }
    }
  }

  Future<void> _unlinkFromContainer(NFCTagStoredRegistration tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink from Container'),
        content: Text(
          'Remove link between this NFC tag and "${tag.containerName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (tag.containerId != null) {
        await ContainerService.unlinkNFCTag(tag.containerId!);
      }
      await NFCTagStorageService.unlinkTagFromContainer(tag.id);
      _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag unlinked from container')),
        );
      }
    }
  }

  void _showNFCDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nfc_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('NFC Not Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_nfcStatusMessage ?? 'NFC is not available on this device.'),
            const SizedBox(height: 16),
            const Text(
              'To use NFC tags:\n'
              '• iOS: Go to Settings > NFC\n'
              '• Android: Go to Settings > Connected devices > NFC',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('NFC Tag Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.containerId != null ? 'Link NFC Tag' : 'NFC Tag Management',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tags', icon: Icon(Icons.list)),
            Tab(text: 'Help', icon: Icon(Icons.help_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTagsList(), _buildHelpTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerNewTag,
        icon: const Icon(Icons.nfc),
        label: const Text('Register New Tag'),
      ),
    );
  }

  Widget _buildTagsList() {
    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No NFC Tags Registered',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Register New Tag" to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _registerNewTag,
              icon: const Icon(Icons.add),
              label: const Text('Register New Tag'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTags(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isLinkedToCurrentContainer =
              widget.containerId != null &&
              tag.containerId == widget.containerId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isLinkedToCurrentContainer
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(tag.status),
                child: const Icon(Icons.nfc, color: Colors.white),
              ),
              title: Text(
                tag.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag.description.isNotEmpty)
                    Text(
                      tag.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (tag.containerId != null) ...[
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag.containerName ?? 'Container',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'ID: ${tag.tagId.substring(0, tag.tagId.length.clamp(0, 12))}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editTag(tag);
                      break;
                    case 'link':
                      _linkToContainer(tag);
                      break;
                    case 'unlink':
                      _unlinkFromContainer(tag);
                      break;
                    case 'view_container':
                      if (tag.containerId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContainerDetailScreen(
                              containerId: tag.containerId!,
                            ),
                          ),
                        );
                      }
                      break;
                    case 'delete':
                      _deleteTag(tag);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (tag.containerId == null)
                    const PopupMenuItem(
                      value: 'link',
                      child: ListTile(
                        leading: Icon(Icons.link),
                        title: Text('Link to Container'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else ...[
                    const PopupMenuItem(
                      value: 'view_container',
                      child: ListTile(
                        leading: Icon(Icons.inventory_2),
                        title: Text('View Container'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'unlink',
                      child: ListTile(
                        leading: Icon(Icons.link_off),
                        title: Text('Unlink'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              onTap: () => _editTag(tag),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(NFCTagStatus status) {
    switch (status) {
      case NFCTagStatus.active:
        return Colors.green;
      case NFCTagStatus.inactive:
        return Colors.grey;
      case NFCTagStatus.pending:
        return Colors.orange;
      case NFCTagStatus.error:
        return Colors.red;
    }
  }

  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpSection(
            title: '📱 Where to Buy NFC Tags',
            content: '''
**Recommended NFC Tags for SSS App:**

• **NTAG213** (144 bytes) - Best for simple container links
• **NTAG215** (504 bytes) - Good balance of storage and price
• **NTAG216** (888 bytes) - Maximum storage for detailed info

**Where to Purchase:**

🛒 **Amazon**
- Search "NTAG215 NFC stickers"
- 25-pack typically \$8-15 USD
- Look for "writable" and "blank" tags

🛒 **AliExpress**
- Bulk packs available (50-100 tags)
- Very affordable (\$5-10 for 50 tags)
- Shipping takes 2-4 weeks

🛒 **Specialty NFC Stores**
- GoToTags.com
- NFCTagify.com
- TagStand.com

**Tag Format Tips:**
• Choose circular stickers (25mm) for containers
• Rectangle stickers work well on shelves
• Waterproof tags for kitchen/bathroom use
• Anti-metal tags if attaching to metal containers
''',
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: '📝 How to Register a Tag',
            content: '''
**Step 1: Prepare Your Tag**
• Remove the protective film from the NFC sticker
• Position it on a flat surface (not on metal!)

**Step 2: Register in App**
1. Tap "Register New Tag" button
2. Fill in the title and description
3. Optionally add tags for easy searching
4. Tap "Write & Register"

**Step 3: Scan the Tag**
• iOS: Hold the top of your iPhone near the tag
• Android: Hold the back of your phone near the tag
• Keep it steady for 2-3 seconds

**Step 4: Link to Container (Optional)**
• After registration, link the tag to a container
• Now scanning the tag opens that container!

**Tips:**
• Write on clean, new tags (easier to write)
• Don't move the phone during writing
• If it fails, try positioning the phone differently
''',
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: '🔧 Troubleshooting',
            content: '''
**"NFC Not Available" Error**

iOS:
• Make sure you have iPhone 7 or newer
• Go to Settings > General > NFC (if available)
• Background Tag Reading must be enabled

Android:
• Go to Settings > Connected devices > NFC
• Toggle NFC on
• Some phones have it under "More connections"

**"Write Failed" Error**

• Tag may be locked or damaged
• Try a different tag
• Make sure tag is NTAG type (not MIFARE)
• Check tag isn't near metal surface

**"Tag Not Detected" Error**

• Move phone slowly over the tag
• Try different positions
• On iPhone, NFC reader is at top
• On Android, it's usually in the center-back
• Some phone cases block NFC - remove case

**Tag Shows "Unknown" When Scanned**

• The tag contains data from another app
• You can overwrite it with a new registration
• Or use a fresh, blank tag
''',
          ),
          const SizedBox(height: 24),
          _buildHelpSection(
            title: '✏️ Modifying Tags',
            content: '''
**To Update Tag Data:**

1. Find the tag in "My Tags" list
2. Tap the tag or select "Edit" from menu
3. Update the title, description, or tags
4. Tap "Save Changes"
5. Scan the physical tag to write updates

**To Unlink from Container:**

1. Select "Unlink" from the tag's menu
2. The tag remains registered but not linked
3. You can link it to a different container later

**To Delete a Tag Registration:**

1. Select "Delete" from the tag's menu
2. Confirm the deletion
3. Note: This only removes from app
4. Physical tag keeps its data (can be rewritten)

**To Completely Erase a Tag:**

1. Register it again with empty/placeholder data
2. Or use a separate NFC app to format it
''',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHelpSection({required String title, required String content}) {
    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(content)),
        ],
      ),
    );
  }
}

/// Dialog/Screen for registering a new NFC tag
class _NFCTagRegisterDialog extends StatefulWidget {
  final String? containerId;
  final String? containerName;

  const _NFCTagRegisterDialog({this.containerId, this.containerName});

  @override
  State<_NFCTagRegisterDialog> createState() => _NFCTagRegisterDialogState();
}

class _NFCTagRegisterDialogState extends State<_NFCTagRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();

  final List<String> _tags = [];
  bool _isWriting = false;
  bool _linkToContainer = true;
  String? _errorMessage;
  String? _successMessage;
  _RegisterStep _currentStep = _RegisterStep.form;

  @override
  void initState() {
    super.initState();
    _linkToContainer = widget.containerId != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _writeAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isWriting = true;
      _errorMessage = null;
      _successMessage = null;
      _currentStep = _RegisterStep.scanning;
    });

    try {
      // Generate deep link for this registration
      final registrationId = NFCTagStorageService.generateId();
      final deepLink = 'sss://nfc/$registrationId';

      // Write to NFC tag
      final result = await NFCService.writeNFCTag(data: deepLink);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final tagId = result['tagId'] as String? ?? 'unknown';

      if (success) {
        // Check if tag is already registered
        if (NFCTagStorageService.isPhysicalTagRegistered(tagId)) {
          setState(() {
            _errorMessage =
                'This tag is already registered. Please use a different tag or edit the existing registration.';
            _isWriting = false;
            _currentStep = _RegisterStep.form;
          });
          return;
        }

        // Create and save registration
        final registration = NFCTagStoredRegistration(
          id: registrationId,
          tagId: tagId,
          containerId: _linkToContainer ? widget.containerId : null,
          containerName: _linkToContainer ? widget.containerName : null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _tags,
          deepLink: deepLink,
          createdAt: DateTime.now(),
          status: NFCTagStatus.active,
        );

        await NFCTagStorageService.saveTag(registration);

        // Link to container if specified
        if (_linkToContainer && widget.containerId != null) {
          await ContainerService.linkNFCTag(widget.containerId!, tagId);
        }

        setState(() {
          _successMessage = 'Tag registered successfully!';
          _isWriting = false;
          _currentStep = _RegisterStep.success;
        });

        // Wait and return
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, registration);
        }
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        setState(() {
          _errorMessage = 'Failed to write to tag: $error';
          _isWriting = false;
          _currentStep = _RegisterStep.form;
        });
      }
    } catch (e) {
      debugPrint('[NFCRegister] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isWriting = false;
          _currentStep = _RegisterStep.form;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New NFC Tag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Messages
              if (_successMessage != null)
                _buildMessageCard(_successMessage!, isSuccess: true),
              if (_errorMessage != null)
                _buildMessageCard(_errorMessage!, isSuccess: false),

              // Form (only show when not scanning)
              if (_currentStep == _RegisterStep.form) ...[
                // Link to container option
                if (widget.containerId != null) ...[
                  SwitchListTile(
                    value: _linkToContainer,
                    onChanged: (value) =>
                        setState(() => _linkToContainer = value),
                    title: const Text('Link to Container'),
                    subtitle: Text(widget.containerName ?? 'Container'),
                    secondary: const Icon(Icons.link),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Winter Clothes Box',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add details about what\'s stored',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 300,
                ),
                const SizedBox(height: 16),

                // Tags
                const Text(
                  'Tags (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagInputController,
                        decoration: const InputDecoration(
                          hintText: 'Add a tag',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTag,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeTag(tag),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),

                // Write button
                ElevatedButton.icon(
                  onPressed: _isWriting ? null : _writeAndRegister,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Write & Register Tag'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              // Scanning state
              if (_currentStep == _RegisterStep.scanning) _buildScanningUI(),

              // Success state
              if (_currentStep == _RegisterStep.success) _buildSuccessUI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Fill Form', _currentStep.index >= 0),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep.index >= 1 ? Colors.green : Colors.grey,
          ),
        ),
        _buildStepCircle(2, 'Scan Tag', _currentStep.index >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep.index >= 2 ? Colors.green : Colors.grey,
          ),
        ),
        _buildStepCircle(3, 'Done', _currentStep.index >= 2),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? Colors.green : Colors.grey,
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(String message, {required bool isSuccess}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningUI() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          const Text(
            'Ready to Scan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              children: [
                Icon(Icons.smartphone, size: 48, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                Text(
                  'Hold your phone near the NFC tag',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Position the top (iPhone) or back (Android) of your phone near the sticker.\n'
                  'Keep it steady for 2-3 seconds.',
                  style: TextStyle(color: Colors.orange.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              NFCService.stopSession();
              setState(() {
                _isWriting = false;
                _currentStep = _RegisterStep.form;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tag Registered Successfully!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'The NFC tag has been written and registered.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum _RegisterStep { form, scanning, success }

/// Screen for editing an existing NFC tag registration
class _NFCTagEditScreen extends StatefulWidget {
  final NFCTagStoredRegistration tag;

  const _NFCTagEditScreen({required this.tag});

  @override
  State<_NFCTagEditScreen> createState() => _NFCTagEditScreenState();
}

class _NFCTagEditScreenState extends State<_NFCTagEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _tagInputController = TextEditingController();

  late List<String> _tags;
  bool _isSaving = false;
  bool _rewriteTag = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tag.title);
    _descriptionController = TextEditingController(
      text: widget.tag.description,
    );
    _tags = List.from(widget.tag.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Update the registration
      final updated = widget.tag.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        lastModified: DateTime.now(),
      );

      // If rewriting to physical tag
      if (_rewriteTag) {
        final result = await NFCService.writeNFCTag(data: updated.deepLink);
        if (!(result['success'] as bool? ?? false)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to write to tag: ${result['error']}'),
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      await NFCTagStorageService.updateTag(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag updated successfully')),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit NFC Tag'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tag info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.nfc, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Physical Tag ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.tag.tagId,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.tag.containerId != null) ...[
                        const Divider(),
                        Row(
                          children: [
                            const Icon(
                              Icons.link,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Linked to: ${widget.tag.containerName ?? "Container"}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                'Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _addTag, child: const Text('Add')),
                ],
              ),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Rewrite option
              SwitchListTile(
                value: _rewriteTag,
                onChanged: (value) => setState(() => _rewriteTag = value),
                title: const Text('Rewrite Physical Tag'),
                subtitle: const Text(
                  'Also update the data on the physical NFC tag',
                ),
                secondary: const Icon(Icons.nfc),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _rewriteTag ? 'Save & Write to Tag' : 'Save Changes',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
