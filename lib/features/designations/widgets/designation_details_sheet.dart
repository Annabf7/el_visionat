import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/profile/models/profile_model.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';
import 'edit_designation_dialog.dart';

/// Widget professional per mostrar els detalls d'una designació
class DesignationDetailsSheet extends StatefulWidget {
  final DesignationModel designation;

  const DesignationDetailsSheet({super.key, required this.designation});

  @override
  State<DesignationDetailsSheet> createState() =>
      _DesignationDetailsSheetState();
}

class _DesignationDetailsSheetState extends State<DesignationDetailsSheet> {
  late TextEditingController _notesController;
  late TextEditingController _partnerNotesController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isEditingPartnerNotes = false;
  bool _isSavingPartnerNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.designation.notes);
    _partnerNotesController = TextEditingController(text: widget.designation.refereePartnerNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _partnerNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);

    final repository = DesignationsRepository();
    final success = await repository.updateNotes(
      widget.designation.id,
      _notesController.text,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apunts guardats correctament'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error guardant els apunts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePartnerNotes() async {
    setState(() => _isSavingPartnerNotes = true);

    final repository = DesignationsRepository();
    final success = await repository.updateRefereePartnerNotes(
      widget.designation.id,
      _partnerNotesController.text,
    );

    if (mounted) {
      setState(() {
        _isSavingPartnerNotes = false;
        _isEditingPartnerNotes = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anotacions del company/a guardades correctament'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error guardant les anotacions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editDesignation(BuildContext context) async {
    String userHomeAddress = '';
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final profile = ProfileModel.fromMap(userData);

          if (profile.homeAddress.isComplete) {
            userHomeAddress = profile.homeAddress.fullAddress;
          }
        }
      } catch (e) {
        userHomeAddress = '';
      }
    }

    if (!context.mounted) return;

    Navigator.pop(context);

    await showDialog<bool>(
      context: context,
      builder: (context) => EditDesignationDialog(
        designation: widget.designation,
        userHomeAddress: userHomeAddress,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar designació'),
        content: const Text(
          'Estàs segur que vols eliminar aquesta designació? '
          'Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = DesignationsRepository();
      final success = await repository.deleteDesignation(widget.designation.id);

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Designació eliminada correctament'
                  : 'Error eliminant la designació',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'ca_ES');
    final timeFormat = DateFormat('HH:mm', 'ca_ES');
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            // Contingut principal
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.grisBody.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        // Hero Header amb gradient
                        _buildHeroHeader(dateFormat, timeFormat),
                        const SizedBox(height: 24),

                        // Informació del partit
                        _buildMatchInfo(),
                        const SizedBox(height: 24),

                        // Detall econòmic
                        _buildEconomicDetails(currencyFormat),
                        const SizedBox(height: 24),

                        // Apunts personals
                        _buildNotes(),

                        // Company/companya àrbitre (només si existeix)
                        if (widget.designation.refereePartner?.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          _buildRefereePartnerSection(),
                        ],

                        const SizedBox(height: 32),

                        // Botons d'acció
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Botó de tancar flotant (sempre visible per sobre de tot)
            Positioned(
              top: 8,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.grisPistacho,
                  iconSize: 24,
                  tooltip: 'Tancar',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroHeader(DateFormat dateFormat, DateFormat timeFormat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lilaMitja.withValues(alpha: 0.15),
            AppTheme.lilaClar.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lilaMitja.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lilaMitja.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data i hora
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.lilaMitja,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(widget.designation.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.grisBody.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(widget.designation.date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grisBody.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Equips amb disseny vs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grisBody.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.designation.localTeam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.lilaMitja,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'VISITANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grisBody.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.designation.visitantTeam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chips informatius
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCompactChip(
                Icons.tag_rounded,
                '#${widget.designation.matchNumber}',
                AppTheme.porpraFosc,
              ),
              _buildCompactChip(
                Icons.sports_rounded,
                widget.designation.role == 'principal'
                    ? 'Principal'
                    : 'Auxiliar',
                AppTheme.lilaMitja,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.info_outline_rounded,
          'Informació del partit',
          AppTheme.lilaMitja,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lilaMitja.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Fila 1: Categoria i Competició
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.category_rounded,
                      'Categoria',
                      widget.designation.category,
                    ),
                  ),
                  if (widget.designation.competition.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.emoji_events_rounded,
                        'Competició',
                        widget.designation.competition,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // Fila 2: Pavelló i Adreça
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.location_on_rounded,
                      'Pavelló',
                      widget.designation.location,
                    ),
                  ),
                  if (widget.designation.locationAddress.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.map_rounded,
                        'Adreça',
                        widget.designation.locationAddress,
                      ),
                    ),
                  ],
                ],
              ),
              // Fila 3: Distància (si existeix)
              if (widget.designation.kilometers > 0) ...[
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.route_rounded,
                  'Distància',
                  '${widget.designation.kilometers.toStringAsFixed(1)} km',
                  highlight: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEconomicDetails(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.account_balance_wallet_rounded,
          'Detall econòmic',
          AppTheme.mostassa,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEarningCard(
                'Drets',
                currencyFormat.format(widget.designation.earnings.rights),
                Icons.gavel_rounded,
                AppTheme.lilaMitja,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildEarningCard(
                'Km',
                currencyFormat.format(
                  widget.designation.earnings.kilometersAmount,
                ),
                Icons.local_gas_station_rounded,
                AppTheme.lilaClar,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildEarningCard(
                'Dietes',
                currencyFormat.format(widget.designation.earnings.allowance),
                Icons.restaurant_rounded,
                AppTheme.grisPistacho,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildEarningCard(
                'TOTAL',
                currencyFormat.format(widget.designation.earnings.total),
                Icons.payments_rounded,
                AppTheme.mostassa,
                isTotal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader(
              Icons.note_rounded,
              'Apunts personals',
              AppTheme.lilaMitja,
            ),
            const Spacer(),
            if (!_isEditing)
              TextButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.lilaMitja,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Afegeix apunts sobre aquest partit...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grisPistacho.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                _notesController.text =
                                    widget.designation.notes ?? '';
                              });
                            },
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNotes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lilaMitja,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.lilaClar.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              widget.designation.notes?.isEmpty ?? true
                  ? 'Encara no hi ha apunts per aquest partit'
                  : widget.designation.notes!,
              style: TextStyle(
                fontSize: 14,
                color: widget.designation.notes?.isEmpty ?? true
                    ? AppTheme.grisBody.withValues(alpha: 0.6)
                    : AppTheme.textBlackLow,
                fontStyle: widget.designation.notes?.isEmpty ?? true
                    ? FontStyle.italic
                    : FontStyle.normal,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRefereePartnerSection() {
    // Determinar títol segons el rol
    final isReferee = widget.designation.role == 'principal' ||
                      widget.designation.role == 'auxiliar';
    final sectionTitle = isReferee
        ? 'Company/a àrbitre'
        : 'Companys/es de taula';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader(
              Icons.people_rounded,
              sectionTitle,
              AppTheme.grisPistacho,
            ),
            const Spacer(),
            if (!_isEditingPartnerNotes)
              TextButton.icon(
                onPressed: () => setState(() => _isEditingPartnerNotes = true),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.grisPistacho,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Mostrar nom del company/companya
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.grisPistacho.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.grisPistacho.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.grisPistacho,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.designation.refereePartner ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textBlackLow,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Anotacions editables
        if (_isEditingPartnerNotes)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _partnerNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Afegeix anotacions sobre el company/companya...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grisPistacho.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSavingPartnerNotes
                          ? null
                          : () {
                              setState(() {
                                _isEditingPartnerNotes = false;
                                _partnerNotesController.text =
                                    widget.designation.refereePartnerNotes ?? '';
                              });
                            },
                      child: const Text('Cancel·lar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSavingPartnerNotes ? null : _savePartnerNotes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.grisPistacho,
                      ),
                      child: _isSavingPartnerNotes
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              widget.designation.refereePartnerNotes?.isEmpty ?? true
                  ? 'Encara no hi ha anotacions sobre el company/companya'
                  : widget.designation.refereePartnerNotes!,
              style: TextStyle(
                fontSize: 14,
                color: widget.designation.refereePartnerNotes?.isEmpty ?? true
                    ? AppTheme.grisBody.withValues(alpha: 0.6)
                    : AppTheme.textBlackLow,
                fontStyle: widget.designation.refereePartnerNotes?.isEmpty ?? true
                    ? FontStyle.italic
                    : FontStyle.normal,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editDesignation(context),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar designació'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lilaMitja,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar designació'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.lilaMitja,
              side: const BorderSide(color: AppTheme.lilaMitja, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.porpraFosc,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.lilaMitja.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.lilaMitja),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grisBody.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: highlight ? AppTheme.lilaMitja : AppTheme.textBlackLow,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningCard(
    String label,
    String amount,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isTotal ? 0.4 : 0.2),
          width: isTotal ? 2 : 1.5,
        ),
        boxShadow: isTotal
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isTotal ? 24 : 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
