import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/season_goals_model.dart';
import 'goals_history_dialog.dart';

/// Widget que mostra els objectius de la temporada
/// Segueix l'aparença del prototip Figma amb seccions expandibles
/// Guarda i carrega dades a Firebase automàticament
/// Inclou sistema d'evolució amb estats i historial
class SeasonGoalsWidget extends StatefulWidget {
  final SeasonGoals initialGoals;

  const SeasonGoalsWidget({
    super.key,
    this.initialGoals = const SeasonGoals(),
  });

  @override
  State<SeasonGoalsWidget> createState() => _SeasonGoalsWidgetState();
}

class _SeasonGoalsWidgetState extends State<SeasonGoalsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estats d'expansió per cada secció
  bool _isPuntsForts = false;
  bool _isPuntsMillorar = false;
  bool _isObjectiusTrimestrals = false;
  bool _isObjectiuTemporada = false;

  // Season goals actuals (amb estats)
  late SeasonGoals _currentGoals;

  // Controladors de text per punts forts (sense estat, descriptius)
  late final List<TextEditingController> _puntsFortControllers;

  // Controladors per objectius amb estat
  late final List<TextEditingController> _puntsMillorarControllers;
  late final List<TextEditingController> _objectiusTrimestralsControllers;
  late final TextEditingController _objectiuTemporadaController;

  @override
  void initState() {
    super.initState();
    _currentGoals = widget.initialGoals;

    // Inicialitzar controladors per punts forts (strings simples)
    _puntsFortControllers = List.generate(
      3,
      (i) => TextEditingController(text: _currentGoals.puntsForts[i]),
    );

    // Inicialitzar controladors per objectius amb estat
    _puntsMillorarControllers = List.generate(
      3,
      (i) => TextEditingController(text: _currentGoals.puntsMillorar[i].text),
    );

    _objectiusTrimestralsControllers = List.generate(
      3,
      (i) => TextEditingController(text: _currentGoals.objectiusTrimestrals[i].text),
    );

    _objectiuTemporadaController =
        TextEditingController(text: _currentGoals.objectiuTemporada.text);
  }

  @override
  void dispose() {
    for (var controller in _puntsFortControllers) {
      controller.dispose();
    }
    for (var controller in _puntsMillorarControllers) {
      controller.dispose();
    }
    for (var controller in _objectiusTrimestralsControllers) {
      controller.dispose();
    }
    _objectiuTemporadaController.dispose();
    super.dispose();
  }

  /// Guarda els objectius a Firebase
  Future<void> _saveGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Construir SeasonGoals actualitzat
      final updatedGoals = _currentGoals.copyWith(
        puntsForts: _puntsFortControllers.map((c) => c.text.trim()).toList(),
        puntsMillorar: List.generate(
          3,
          (i) => _currentGoals.puntsMillorar[i].copyWith(
            text: _puntsMillorarControllers[i].text.trim(),
            lastModified: DateTime.now(),
          ),
        ),
        objectiusTrimestrals: List.generate(
          3,
          (i) => _currentGoals.objectiusTrimestrals[i].copyWith(
            text: _objectiusTrimestralsControllers[i].text.trim(),
            lastModified: DateTime.now(),
          ),
        ),
        objectiuTemporada: _currentGoals.objectiuTemporada.copyWith(
          text: _objectiuTemporadaController.text.trim(),
          lastModified: DateTime.now(),
        ),
      );

      await _firestore.collection('users').doc(user.uid).update({
        'seasonGoals': updatedGoals.toMap(),
      });

      setState(() {
        _currentGoals = updatedGoals;
      });

      debugPrint('✅ Objectius de temporada guardats correctament');
    } catch (e) {
      debugPrint('❌ Error guardant objectius: $e');
    }
  }

  /// Canvia l'estat d'un objectiu entre actiu i completat (només 2 estats)
  Future<void> _toggleGoalStatus(String category, int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<Goal> goals;

      switch (category) {
        case 'puntsMillorar':
          goals = List.from(_currentGoals.puntsMillorar);
          break;
        case 'objectiusTrimestrals':
          goals = List.from(_currentGoals.objectiusTrimestrals);
          break;
        case 'objectiuTemporada':
          // L'objectiu de temporada és únic
          final currentGoal = _currentGoals.objectiuTemporada;
          final newStatus = currentGoal.status == GoalStatus.active
              ? GoalStatus.completed
              : GoalStatus.active;

          final updatedGoals = _currentGoals.copyWith(
            objectiuTemporada: currentGoal.copyWith(
              status: newStatus,
              lastModified: DateTime.now(),
            ),
          );

          await _firestore.collection('users').doc(user.uid).update({
            'seasonGoals': updatedGoals.toMap(),
          });

          setState(() {
            _currentGoals = updatedGoals;
          });
          return;
        default:
          return;
      }

      // Canviar estat entre actiu i completat
      final currentGoal = goals[index];
      final newStatus = currentGoal.status == GoalStatus.active
          ? GoalStatus.completed
          : GoalStatus.active;

      goals[index] = currentGoal.copyWith(
        status: newStatus,
        lastModified: DateTime.now(),
      );

      final updatedGoals = _currentGoals.copyWith(
        puntsMillorar: category == 'puntsMillorar' ? goals : null,
        objectiusTrimestrals: category == 'objectiusTrimestrals' ? goals : null,
      );

      await _firestore.collection('users').doc(user.uid).update({
        'seasonGoals': updatedGoals.toMap(),
      });

      setState(() {
        _currentGoals = updatedGoals;
      });
    } catch (e) {
      debugPrint('❌ Error canviant estat d\'objectiu: $e');
    }
  }

  /// Arxiva un objectiu completat a l'historial
  Future<void> _archiveGoal(String category, int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Goal goalToArchive;
      List<Goal>? updatedPuntsMillorar;
      List<Goal>? updatedObjectiusTrimestrals;
      Goal? updatedObjectiuTemporada;

      switch (category) {
        case 'puntsMillorar':
          final goals = List<Goal>.from(_currentGoals.puntsMillorar);
          goalToArchive = goals[index];
          goals[index] = const Goal(); // Reiniciar
          updatedPuntsMillorar = goals;
          break;
        case 'objectiusTrimestrals':
          final goals = List<Goal>.from(_currentGoals.objectiusTrimestrals);
          goalToArchive = goals[index];
          goals[index] = const Goal(); // Reiniciar
          updatedObjectiusTrimestrals = goals;
          break;
        case 'objectiuTemporada':
          goalToArchive = _currentGoals.objectiuTemporada;
          updatedObjectiuTemporada = const Goal();
          break;
        default:
          return;
      }

      // Afegir a l'historial
      final historyEntry = GoalHistoryEntry(
        text: goalToArchive.text,
        achievedDate: DateTime.now(),
        category: category,
      );

      final updatedGoals = _currentGoals.copyWith(
        puntsMillorar: updatedPuntsMillorar,
        objectiusTrimestrals: updatedObjectiusTrimestrals,
        objectiuTemporada: updatedObjectiuTemporada,
        history: [..._currentGoals.history, historyEntry],
      );

      await _firestore.collection('users').doc(user.uid).update({
        'seasonGoals': updatedGoals.toMap(),
      });

      setState(() {
        _currentGoals = updatedGoals;
        if (category == 'puntsMillorar') {
          _puntsMillorarControllers[index].clear();
        } else if (category == 'objectiusTrimestrals') {
          _objectiusTrimestralsControllers[index].clear();
        } else if (category == 'objectiuTemporada') {
          _objectiuTemporadaController.clear();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📦 Objectiu arxivat a l\'historial'),
            backgroundColor: AppTheme.mostassa,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error arxivant objectiu: $e');
    }
  }

  /// Restaura un objectiu des de l'historial
  Future<void> _restoreFromHistory(GoalHistoryEntry entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Eliminar de l'historial
      final updatedHistory = _currentGoals.history.where((e) => e != entry).toList();

      // Crear Goal restaurat (marcat com a completat)
      final restoredGoal = Goal(
        text: entry.text,
        status: GoalStatus.completed,
        lastModified: DateTime.now(),
      );

      // Afegir a la categoria corresponent (primera posició buida o última)
      List<Goal>? updatedGoals;
      int targetIndex = -1;

      switch (entry.category) {
        case 'puntsMillorar':
          updatedGoals = List.from(_currentGoals.puntsMillorar);
          targetIndex = updatedGoals.indexWhere((g) => g.isEmpty);
          if (targetIndex == -1) targetIndex = updatedGoals.length - 1;
          updatedGoals[targetIndex] = restoredGoal;
          _puntsMillorarControllers[targetIndex].text = entry.text;
          break;
        case 'objectiusTrimestrals':
          updatedGoals = List.from(_currentGoals.objectiusTrimestrals);
          targetIndex = updatedGoals.indexWhere((g) => g.isEmpty);
          if (targetIndex == -1) targetIndex = updatedGoals.length - 1;
          updatedGoals[targetIndex] = restoredGoal;
          _objectiusTrimestralsControllers[targetIndex].text = entry.text;
          break;
        case 'objectiuTemporada':
          _objectiuTemporadaController.text = entry.text;
          break;
      }

      final updatedSeasonGoals = _currentGoals.copyWith(
        puntsMillorar: entry.category == 'puntsMillorar' ? updatedGoals : null,
        objectiusTrimestrals: entry.category == 'objectiusTrimestrals' ? updatedGoals : null,
        objectiuTemporada: entry.category == 'objectiuTemporada' ? restoredGoal : null,
        history: updatedHistory,
      );

      await _firestore.collection('users').doc(user.uid).update({
        'seasonGoals': updatedSeasonGoals.toMap(),
      });

      setState(() {
        _currentGoals = updatedSeasonGoals;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('↩️ Objectiu restaurat correctament'),
            backgroundColor: AppTheme.mostassa,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error restaurant objectiu: $e');
    }
  }

  /// Elimina permanentment un objectiu de l'historial
  Future<void> _deleteFromHistory(GoalHistoryEntry entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedHistory = _currentGoals.history.where((e) => e != entry).toList();

      final updatedGoals = _currentGoals.copyWith(history: updatedHistory);

      await _firestore.collection('users').doc(user.uid).update({
        'seasonGoals': updatedGoals.toMap(),
      });

      setState(() {
        _currentGoals = updatedGoals;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Objectiu eliminat de l\'historial'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error eliminant objectiu de l\'historial: $e');
    }
  }

  /// Mostra el diàleg d'historial
  void _showHistory(String category) {
    showDialog(
      context: context,
      builder: (context) => GoalsHistoryDialog(
        history: _currentGoals.history,
        categoryFilter: category,
        onDelete: _deleteFromHistory,
        onRestore: _restoreFromHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol de la secció
        const Text(
          'Objectius de la Temporada',
          style: TextStyle(
            fontFamily: 'Geist',
            color: AppTheme.textBlackLow,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),

        // Taula d'objectius amb estil coherent
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildGoalItem(
                '3 punts forts',
                itemIndex: 0,
                isFirst: true,
                isExpanded: _isPuntsForts,
                onTap: () => setState(() => _isPuntsForts = !_isPuntsForts),
                expandedContent: _buildPuntsForts(),
                showHistory: false,
              ),
              _buildGoalItem(
                '3 punts a millorar',
                itemIndex: 1,
                isExpanded: _isPuntsMillorar,
                onTap: () => setState(() => _isPuntsMillorar = !_isPuntsMillorar),
                expandedContent: _buildPuntsMillorar(),
                showHistory: true,
                onShowHistory: () => _showHistory('puntsMillorar'),
              ),
              _buildGoalItem(
                '3 objectius trimestrals',
                itemIndex: 2,
                isExpanded: _isObjectiusTrimestrals,
                onTap: () => setState(
                  () => _isObjectiusTrimestrals = !_isObjectiusTrimestrals,
                ),
                expandedContent: _buildObjectiusTrimestrals(),
                showHistory: true,
                onShowHistory: () => _showHistory('objectiusTrimestrals'),
              ),
              _buildGoalItem(
                'Objectiu de temporada',
                itemIndex: 3,
                isLast: true,
                isExpanded: _isObjectiuTemporada,
                onTap: () => setState(
                  () => _isObjectiuTemporada = !_isObjectiuTemporada,
                ),
                expandedContent: _buildObjectiuTemporada(),
                showHistory: true,
                onShowHistory: () => _showHistory('objectiuTemporada'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construeix cada fila de la taula d'objectius
  Widget _buildGoalItem(
    String title, {
    required int itemIndex,
    bool isFirst = false,
    bool isLast = false,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget expandedContent,
    bool showHistory = false,
    VoidCallback? onShowHistory,
  }) {
    final backgroundColor = itemIndex % 2 == 0
        ? AppTheme.grisPistacho.withValues(alpha: 0.4)
        : AppTheme.grisPistacho.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isFirst
            ? const Border(top: BorderSide(color: AppTheme.mostassa, width: 2))
            : null,
        borderRadius: isFirst && !isExpanded
            ? const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              )
            : isLast && !isExpanded
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  )
                : isFirst
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      )
                    : null,
      ),
      child: Column(
        children: [
          // Capçalera clicable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: isFirst && !isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    )
                  : isLast && !isExpanded
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        )
                      : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Títol
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppTheme.textBlackLow,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    Row(
                      children: [
                        // Botó historial
                        if (showHistory && onShowHistory != null)
                          IconButton(
                            icon: const Icon(Icons.history, size: 18),
                            onPressed: onShowHistory,
                            color: AppTheme.mostassa,
                            tooltip: 'Veure historial',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (showHistory) const SizedBox(width: 8),

                        // Icona d'expansió
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.textBlackLow,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contingut expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      )
                    : null,
              ),
              child: expandedContent,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Contingut per "3 punts forts" (sense estat, descriptius)
  Widget _buildPuntsForts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableBulletPoint(
          _puntsFortControllers[0],
          'Descriu el teu primer punt fort com a àrbitre',
        ),
        _buildEditableBulletPoint(
          _puntsFortControllers[1],
          'Indica el teu segon punt fort destacat',
        ),
        _buildEditableBulletPoint(
          _puntsFortControllers[2],
          'Afegeix un tercer punt fort rellevant',
        ),
      ],
    );
  }

  /// Contingut per "3 punts a millorar" (amb estat i checkbox)
  Widget _buildPuntsMillorar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3; i++)
          _buildGoalWithStatus(
            _puntsMillorarControllers[i],
            i == 0
                ? 'Identifica el primer aspecte a desenvolupar'
                : i == 1
                    ? 'Defineix un segon àmbit de millora'
                    : 'Especifica una tercera àrea d\'oportunitat',
            _currentGoals.puntsMillorar[i].status,
            () => _toggleGoalStatus('puntsMillorar', i),
            category: 'puntsMillorar',
            index: i,
          ),
      ],
    );
  }

  /// Contingut per "3 objectius trimestrals" (amb estat i checkbox)
  Widget _buildObjectiusTrimestrals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3; i++)
          _buildGoalWithStatus(
            _objectiusTrimestralsControllers[i],
            i == 0
                ? 'Estableix el primer objectiu per aquest trimestre'
                : i == 1
                    ? 'Defineix un segon repte trimestral'
                    : 'Fixa una tercera fita a assolir aquest trimestre',
            _currentGoals.objectiusTrimestrals[i].status,
            () => _toggleGoalStatus('objectiusTrimestrals', i),
            category: 'objectiusTrimestrals',
            index: i,
          ),
      ],
    );
  }

  /// Contingut per "Objectiu de temporada" (amb estat i checkbox)
  Widget _buildObjectiuTemporada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoalWithStatus(
          _objectiuTemporadaController,
          'Descriu el teu objectiu principal per aquesta temporada',
          _currentGoals.objectiuTemporada.status,
          () => _toggleGoalStatus('objectiuTemporada', 0),
          category: 'objectiuTemporada',
          index: 0,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.mostassa.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.mostassa.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.star, color: AppTheme.mostassa, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Objectiu principal de desenvolupament professional',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.textBlackLow,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget auxiliar per crear punts editables amb bullet i placeholder (sense estat)
  Widget _buildEditableBulletPoint(
    TextEditingController controller,
    String placeholder,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.mostassa,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 1.4,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.textBlackLow.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              autocorrect: true,
              enableSuggestions: true,
              onSubmitted: (value) async {
                await _saveGoals();
                if (mounted) {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget per objectius amb estat (checkbox + text + botó arxivar)
  Widget _buildGoalWithStatus(
    TextEditingController controller,
    String placeholder,
    GoalStatus status,
    VoidCallback onStatusToggle, {
    String category = '',
    int index = 0,
  }) {
    final isCompleted = status == GoalStatus.completed;
    final hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox d'estat (només 2 estats: actiu o completat)
          GestureDetector(
            onTap: hasText ? onStatusToggle : null,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.mostassa : Colors.transparent,
                border: Border.all(
                  color: !hasText
                      ? AppTheme.textBlackLow.withValues(alpha: 0.2)
                      : AppTheme.mostassa,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Camp de text
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 1.4,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.textBlackLow.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              autocorrect: true,
              enableSuggestions: true,
              onSubmitted: (value) async {
                await _saveGoals();
                if (mounted) {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),

          // Botó arxivar (només visible si està completat)
          if (isCompleted && hasText)
            IconButton(
              icon: const Icon(Icons.archive_outlined, size: 18),
              onPressed: () => _archiveGoal(category, index),
              color: AppTheme.mostassa,
              tooltip: 'Arxivar objectiu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}