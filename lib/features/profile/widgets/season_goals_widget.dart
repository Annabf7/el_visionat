import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Widget que mostra els objectius de la temporada
/// Segueix l'aparença del prototip Figma amb seccions expandibles
class SeasonGoalsWidget extends StatefulWidget {
  const SeasonGoalsWidget({super.key});

  @override
  State<SeasonGoalsWidget> createState() => _SeasonGoalsWidgetState();
}

class _SeasonGoalsWidgetState extends State<SeasonGoalsWidget> {
  // Estats d'expansió per cada secció
  bool _isPuntsForts = false;
  bool _isPuntsMillorar = false;
  bool _isObjectiusTrimestrals = false;
  bool _isObjectiuTemporada = false;

  // Controladors de text per punts forts
  final TextEditingController _puntFort1Controller = TextEditingController(
    text: 'Excel·lent posicionament en situacions de defensa',
  );
  final TextEditingController _puntFort2Controller = TextEditingController(
    text: 'Comunicació clara i efectiva amb els jugadors',
  );
  final TextEditingController _puntFort3Controller = TextEditingController(
    text: 'Gestió adequada del temps i ritme del partit',
  );

  // Controladors de text per punts a millorar
  final TextEditingController _puntMillorar1Controller = TextEditingController(
    text: 'Millorar la detecció de faltes tècniques subtils',
  );
  final TextEditingController _puntMillorar2Controller = TextEditingController(
    text: 'Treballar la confiança en decisions polèmiques',
  );
  final TextEditingController _puntMillorar3Controller = TextEditingController(
    text: 'Optimitzar el posicionament en contraatacs ràpids',
  );

  // Controladors de text per objectius trimestrals
  final TextEditingController _objectiuTrimestral1Controller =
      TextEditingController(
        text: 'Arbitrar 15 partits de categoria superior aquest trimestre',
      );
  final TextEditingController _objectiuTrimestral2Controller =
      TextEditingController(
        text: 'Completar curs d\'especialització en arbitratge femení',
      );
  final TextEditingController _objectiuTrimestral3Controller =
      TextEditingController(
        text: 'Reduir mitjana d\'infraccions tècniques detectades tardanament',
      );

  // Controlador per objectiu de temporada
  final TextEditingController
  _objectiuTemporadaController = TextEditingController(
    text: 'Aconseguir l\'ascens a categoria Nacional per la propera temporada',
  );

  @override
  void dispose() {
    // Disposar dels controladors
    _puntFort1Controller.dispose();
    _puntFort2Controller.dispose();
    _puntFort3Controller.dispose();
    _puntMillorar1Controller.dispose();
    _puntMillorar2Controller.dispose();
    _puntMillorar3Controller.dispose();
    _objectiuTrimestral1Controller.dispose();
    _objectiuTrimestral2Controller.dispose();
    _objectiuTrimestral3Controller.dispose();
    _objectiuTemporadaController.dispose();
    super.dispose();
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
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 24),

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
              ),
              _buildGoalItem(
                '3 punts a millorar',
                itemIndex: 1,
                isExpanded: _isPuntsMillorar,
                onTap: () =>
                    setState(() => _isPuntsMillorar = !_isPuntsMillorar),
                expandedContent: _buildPuntsMillorar(),
              ),
              _buildGoalItem(
                '3 objectius trimestrals',
                itemIndex: 2,
                isExpanded: _isObjectiusTrimestrals,
                onTap: () => setState(
                  () => _isObjectiusTrimestrals = !_isObjectiusTrimestrals,
                ),
                expandedContent: _buildObjectiusTrimestrals(),
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
  }) {
    // Alternar entre dos tons de gris (mateix estil que altres widgets)
    final backgroundColor = itemIndex % 2 == 0
        ? AppTheme.grisPistacho.withValues(alpha: 0.4) // Més fosc
        : AppTheme.grisPistacho.withValues(alpha: 0.2); // Més clar

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        // Només la primera fila té stroke mostassa superior
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

  /// Contingut per "3 punts forts"
  Widget _buildPuntsForts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableBulletPoint(_puntFort1Controller),
        _buildEditableBulletPoint(_puntFort2Controller),
        _buildEditableBulletPoint(_puntFort3Controller),
      ],
    );
  }

  /// Contingut per "3 punts a millorar"
  Widget _buildPuntsMillorar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableBulletPoint(_puntMillorar1Controller),
        _buildEditableBulletPoint(_puntMillorar2Controller),
        _buildEditableBulletPoint(_puntMillorar3Controller),
      ],
    );
  }

  /// Contingut per "3 objectius trimestrals"
  Widget _buildObjectiusTrimestrals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableBulletPoint(_objectiuTrimestral1Controller),
        _buildEditableBulletPoint(_objectiuTrimestral2Controller),
        _buildEditableBulletPoint(_objectiuTrimestral3Controller),
      ],
    );
  }

  /// Contingut per "Objectiu de temporada"
  Widget _buildObjectiuTemporada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableBulletPoint(_objectiuTemporadaController),
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

  /// Widget auxiliar per crear punts editables amb bullet
  Widget _buildEditableBulletPoint(TextEditingController controller) {
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              autocorrect: true,
              enableSuggestions: true,
              onSubmitted: (value) {
                // Guardar canvis quan l'usuari acabi d'editar
                debugPrint('📝 Objectiu actualitzat: $value');
                FocusScope.of(context).unfocus();
              },
              onChanged: (value) {
                // Actualitzar en temps real per assegurar que els accents es mostrin
                debugPrint('✏️ Text canviat: $value');
              },
            ),
          ),
        ],
      ),
    );
  }
}
