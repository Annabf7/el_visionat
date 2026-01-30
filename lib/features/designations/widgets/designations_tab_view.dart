import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../core/theme/app_theme.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';
import 'designation_details_sheet.dart';

/// Widget que mostra l'historial de designacions per període
class DesignationsTabView extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const DesignationsTabView({super.key, this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    final repository = DesignationsRepository();

    return StreamBuilder<List<DesignationModel>>(
      stream: startDate != null && endDate != null
          ? repository.getDesignationsByPeriod(
              startDate: startDate!,
              endDate: endDate!,
            )
          : repository.getDesignations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error carregant designacions: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final designations = snapshot.data ?? [];

        if (designations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.grisPistacho.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_basketball_outlined,
                      size: 72,
                      color: AppTheme.grisBody.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Encara no tens designacions',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Puja el teu primer PDF amb el botó inferior',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grisBody.withValues(alpha: 0.7),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Agrupar designacions per data (sense hora)
        final groupedByDate = groupBy<DesignationModel, String>(
          designations,
          (designation) => DateFormat('yyyy-MM-dd').format(designation.date),
        );

        // Ordenar dates de més recent a més antic
        final sortedDates = groupedByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final dateDesignations = groupedByDate[dateKey]!;
                final date = DateTime.parse(dateKey);

                return _DateGroup(
                  date: date,
                  designations: dateDesignations,
                  isDesktop: isDesktop,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<DesignationModel> designations;
  final bool isDesktop;

  const _DateGroup({
    required this.date,
    required this.designations,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM', 'ca_ES');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.porpraFosc,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dateFormat.format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.mostassa.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${designations.length} ${designations.length == 1 ? "partit" : "partits"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.porpraFosc,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Designacions
        if (isDesktop)
          // Layout horitzontal per desktop
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: designations.map((designation) {
                return Container(
                  width: 380,
                  constraints: const BoxConstraints(
                    minHeight: 280,
                    maxHeight: 280,
                  ),
                  margin: const EdgeInsets.only(right: 14, bottom: 20),
                  child: _DesignationCard(designation: designation),
                );
              }).toList(),
            ),
          )
        else
          // Layout vertical per mòbil
          ...designations.map((designation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DesignationCard(designation: designation),
            );
          }),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _DesignationCard extends StatelessWidget {
  final DesignationModel designation;

  const _DesignationCard({required this.designation});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'ca_ES');
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.porpraFosc.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDesignationDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header amb hora
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaClar.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lilaClar.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.porpraFosc,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeFormat.format(designation.date),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.porpraFosc,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Equips
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          designation.localTeam,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.grisBody.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'vs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grisBody,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          designation.visitantTeam,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Categoria i rol
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.category_rounded,
                        label: designation.category,
                        color: AppTheme.lilaMitja,
                      ),
                      _InfoChip(
                        icon: Icons.person_rounded,
                        label: designation.role == 'principal'
                            ? 'Principal'
                            : 'Auxiliar',
                        color: AppTheme.lilaMitja,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Localització
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: AppTheme.grisBody.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          designation.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grisBody.withValues(alpha: 0.8),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Divider(
                    height: 24,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.4),
                  ),

                  // Informació econòmica
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EarningDetail(
                        label: 'Drets',
                        amount: currencyFormat.format(
                          designation.earnings.rights,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Km',
                        amount: currencyFormat.format(
                          designation.earnings.kilometersAmount,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Dietes',
                        amount: currencyFormat.format(
                          designation.earnings.allowance,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Total net',
                        amount: currencyFormat.format(
                          designation.earnings.netTotal,
                        ),
                        color: AppTheme.lilaMitja,
                        isTotal: true,
                      ),
                    ],
                  ),

                  // Apunts si n'hi ha
                  if (designation.notes != null &&
                      designation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.lilaClar.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_rounded,
                            size: 14,
                            color: AppTheme.lilaMitja,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              designation.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textBlackLow,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDesignationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DesignationDetailsSheet(designation: designation),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningDetail extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isTotal;

  const _EarningDetail({
    required this.label,
    required this.amount,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

