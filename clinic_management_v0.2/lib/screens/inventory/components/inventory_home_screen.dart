import 'package:flutter/material.dart';
import 'import_inventory_screen.dart';
import 'inventory_status_screen.dart';
import 'export_inventory_screen.dart';
import 'supplier_screen.dart';

class InventoryHomeScreen extends StatefulWidget {
  const InventoryHomeScreen({super.key});

  // Add color constants
  static const primaryColor = Color(0xFF546E7A); // BlueGrey[600]
  static const secondaryColor = Color(0xFF78909C); // BlueGrey[400]
  static const backgroundColor = Color(0xFFECEFF1); // BlueGrey[50]
  static const accentColor = Color(0xFF90A4AE); // BlueGrey[200]
  static const gradientStart = Color(0xFF546E7A); // BlueGrey[600]
  static const gradientEnd = Color(0xFF78909C); // BlueGrey[400]

  @override
  State<InventoryHomeScreen> createState() => _InventoryHomeScreenState();
}

class _InventoryHomeScreenState extends State<InventoryHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý kho',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: InventoryHomeScreen.primaryColor,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              InventoryHomeScreen.gradientStart,
              InventoryHomeScreen.backgroundColor,
            ],
          ),
        ),
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildMenuCard(
              context: context,
              title: 'Nhập kho',
              icon: Icons.add_box,
              subtitle: 'Nhập thuốc và vật tư',
              color: const Color(0xFF66BB6A), // Soft Green
              onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ImportInventoryScreen()),
              ),
            ),
            _buildMenuCard(
              context: context,
              title: 'Tồn kho',
              icon: Icons.inventory,
              subtitle: 'Quản lý tồn kho',
              color: const Color(0xFF42A5F5), // Soft Blue
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InventoryStatusScreen()),
              ),
            ),
            _buildMenuCard(
              context: context,
              title: 'Xuất kho',
              icon: Icons.outbox,
              subtitle: 'Quản lý xuất kho',
              color: const Color(0xFFEC407A), // Soft Pink
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExportInventoryScreen()),
              ),
            ),
            _buildMenuCard(
              context: context,
              title: 'Nhà cung cấp',
              icon: Icons.business,
              subtitle: 'Quản lý nhà cung cấp',
              color: const Color(0xFFFFB74D), // Soft Orange
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _buildMenuCard extends StatefulWidget {
  final BuildContext context;
  final String title;
  final IconData icon;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _buildMenuCard({
    required this.context,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_buildMenuCard> createState() => _buildMenuCardState();
}

class _buildMenuCardState extends State<_buildMenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  Future<void> _handleTap() async {
    setState(() => _isPressed = true);
    
    // Giảm số lần rung và thời gian delay
    for (int i = 0; i < 1; i++) {  // Giảm từ 2 xuống 1 lần
      if (!mounted) return;
      setState(() {
        _controller.value = 0.95;
      });
      await Future.delayed(const Duration(milliseconds: 30));  // Giảm từ 50ms xuống 30ms
      if (!mounted) return;
      setState(() {
        _controller.value = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 30));  // Giảm từ 50ms xuống 30ms
    }

    // Giảm delay trước khi chuyển màn hình
    await Future.delayed(const Duration(milliseconds: 100));  // Giảm từ 200ms xuống 100ms
    
    if (!mounted) return;
    setState(() => _isPressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: widget.color.withOpacity(0.3),
              highlightColor: widget.color.withOpacity(0.15),
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => _handleTap(),
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..scale(_isPressed 
                      ? 0.92
                      : _isHovered 
                          ? 1.05 
                          : _scaleAnimation.value),
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Card(
                    elevation: _isHovered ? 8 : 4,
                    shadowColor: widget.color.withOpacity(_isHovered ? 0.4 : 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.all(_isPressed ? 8 : 12),
                            transform: Matrix4.identity()
                              ..scale(_isPressed ? 0.9 : 1.0),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon, 
                              size: _isHovered ? 50 : 45, 
                              color: widget.color
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.bold,
                              fontSize: _isHovered ? 22 : 20,
                            ),
                            child: Text(widget.title),
                          ),
                          const SizedBox(height: 8),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: _isHovered ? 13 : 12,
                            ),
                            child: Text(
                              widget.subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
