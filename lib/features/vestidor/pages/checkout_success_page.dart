import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/vestidor_order.dart';
import '../services/orders_service.dart';
import '../providers/cart_provider.dart';

/// Pàgina de confirmació de pagament web (retorn de Stripe Checkout)
class CheckoutSuccessPage extends StatefulWidget {
  final String orderId;

  const CheckoutSuccessPage({super.key, required this.orderId});

  @override
  State<CheckoutSuccessPage> createState() => _CheckoutSuccessPageState();
}

class _CheckoutSuccessPageState extends State<CheckoutSuccessPage> {
  bool _cartCleared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cartCleared) {
      _cartCleared = true;
      context.read<CartProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<VestidorOrder?>(
              stream: OrdersService.orderStream(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: AppTheme.porpraFosc,
                  );
                }

                final order = snapshot.data;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.verdeEncert.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 44,
                        color: AppTheme.verdeEncert,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pagament completat!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gràcies per la teva compra. Rebràs un correu de confirmació.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Resum de la comanda
                    if (order != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Comanda',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.porpraFosc,
                                  ),
                                ),
                                Text(
                                  '#${order.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.grisPistacho,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...order.items.map((item) {
                              final name = (item['name'] ?? '') as String;
                              final qty = (item['quantity'] ?? 1) as int;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$name x$qty',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppTheme.porpraFosc,
                                  ),
                                ),
                              );
                            }),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.porpraFosc,
                                  ),
                                ),
                                Text(
                                  order.totalFormatted,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.porpraFosc,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'ID comanda: ${widget.orderId}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.grisPistacho,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Botons de navegació
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/orders',
                          (route) => route.isFirst,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.porpraFosc,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Veure les meves comandes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/vestidor',
                        (route) => route.isFirst,
                      ),
                      child: const Text(
                        'Tornar a la botiga',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mostassa,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
