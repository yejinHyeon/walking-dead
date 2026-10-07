import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/content.dart';
import '../core/tokens.dart';
import '../widgets/ui.dart';

String foodLabel(FoodItem f, Content c) => f.key != null ? (c.foods[f.key] ?? f.key!) : (f.customName ?? '');

String _days(double d) => d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);

/// 목업 Supplies: 지금 가진 것으로 며칠 버티나
class SuppliesScreen extends StatelessWidget {
  const SuppliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.watch<AppState>();
    final c = context.watch<Content>();
    final waterFirst = s.waterRunsOutFirst;

    Widget daysBox(String label, double days, bool low) => Expanded(
          child: AppCard(
            highlight: low,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(l.days(_days(days)), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.suppliesTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 4, T.pad, 24), children: [
        Text(l.suppliesHave, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        gap12,
        AppCard(
          child: Column(children: [
            _Row(l.people, Stepper2(
              value: l.peopleCount(s.people),
              onMinus: () => (s..people = (s.people - 1).clamp(1, 999)).changed(),
              onPlus: () => (s..people += 1).changed(),
            )),
            const Divider(height: 20),
            _Row(l.drinkingWater, Stepper2(
              value: l.liters(s.waterLiters),
              onMinus: () => (s..waterLiters = (s.waterLiters - 1).clamp(0, 9999)).changed(),
              onPlus: () => (s..waterLiters += 1).changed(),
            )),
          ]),
        ),
        gap16,
        SectionLabel(l.foodMeals),
        AppCard(
          child: Column(children: [
            for (var k = 0; k < s.foods.length; k++) ...[
              if (k > 0) const Divider(height: 16),
              Dismissible(
                key: ValueKey('food$k${s.foods[k].key}${s.foods[k].customName}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => (s..foods.removeAt(k)).changed(),
                child: _Row(foodLabel(s.foods[k], c), Stepper2(
                  value: '${s.foods[k].meals}',
                  onMinus: () {
                    s.foods[k].meals = (s.foods[k].meals - 1).clamp(0, 999);
                    s.changed();
                  },
                  onPlus: () {
                    s.foods[k].meals += 1;
                    s.changed();
                  },
                )),
              ),
            ],
            gap8,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(onPressed: () => _addFood(context, s, c), icon: const Icon(Icons.add), label: Text(l.addFood)),
            ),
          ]),
        ),
        gap16,
        Row(children: [
          daysBox(l.byWater, s.waterDays, waterFirst),
          const SizedBox(width: 12),
          daysBox(l.byFood, s.foodDays, !waterFirst),
        ]),
        gap12,
        AppCard(child: Text(waterFirst ? l.adviceWater : l.adviceFood, style: const TextStyle(height: 1.6))),
        gap16,
        BigButton(
          label: l.makeWater,
          icon: Icons.local_drink_outlined,
          primary: false,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen())),
        ),
        gap8,
        BigButton(
          label: l.whatToEat,
          icon: Icons.restaurant_outlined,
          primary: false,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipesScreen())),
        ),
      ]),
    );
  }

  Future<void> _addFood(BuildContext context, AppState s, Content c) async {
    final l = context.l;
    final have = {for (final f in s.foods) f.key};
    final custom = TextEditingController();
    final picked = await showModalBottomSheet<FoodItem>(
      context: context,
      backgroundColor: T.bg,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(T.pad, 16, T.pad, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.addFood, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          gap12,
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in c.foods.entries)
              if (!have.contains(e.key))
                ActionChip(label: Text(e.value), onPressed: () => Navigator.pop(ctx, FoodItem(key: e.key, meals: 1))),
          ]),
          gap12,
          Row(children: [
            Expanded(child: TextField(controller: custom, decoration: InputDecoration(hintText: l.foodName))),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final t = custom.text.trim();
                if (t.isNotEmpty) Navigator.pop(ctx, FoodItem(customName: t, meals: 1));
              },
              child: Text(l.add),
            ),
          ]),
        ]),
      ),
    );
    if (picked != null) (s..foods.add(picked)).changed();
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _Row(this.label, this.trailing);
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        trailing,
      ]);
}

/// 목업 Water
class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  String k = 'boil';
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final m = c.water.firstWhere((x) => x.id == k);
    return AppPage(title: l.waterTitle, children: [
      Segments<String>(items: {for (final x in c.water) x.id: x.label}, value: k, onChanged: (v) => setState(() => k = v)),
      gap16,
      Text(m.intro, style: const TextStyle(fontSize: 16, height: 1.5)),
      gap12,
      StepList(m.steps),
      gap12,
      WarnBox(title: l.waterNever, body: l.waterNeverBody),
    ]);
  }
}

/// 목업 Recipes: 가진 재료로 식사 (불 없이 / 물 없이)
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String f = 'all';
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final have = context.watch<AppState>().availableFoodKeys;
    final list = c.recipes.where((r) => f == 'all' || (f == 'nofire' ? !r.fire : r.waterMl == 0)).toList()
      ..sort((a, b) => _missing(a, have).length.compareTo(_missing(b, have).length));
    return AppPage(title: l.recipesTitle, children: [
      Segments<String>(
        items: {'all': l.filterAll, 'nofire': l.filterNoFire, 'nowater': l.filterNoWater},
        value: f,
        onChanged: (v) => setState(() => f = v),
      ),
      gap16,
      for (final r in list) ...[
        AppCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              _missing(r, have).isEmpty
                  ? Pill(l.recipeAvailable, color: T.info)
                  : Pill(l.recipeMissing(_missing(r, have).map((k) => c.foods[k] ?? k).join(', ')), color: T.muted),
            ]),
            const SizedBox(height: 4),
            Muted(r.ingredients),
            gap8,
            Wrap(spacing: 6, children: [
              Pill(r.fire ? l.fireMinutes(r.fireMin) : l.filterNoFire),
              Pill(r.waterMl == 0 ? l.filterNoWater : l.waterMl(r.waterMl)),
            ]),
          ]),
        ),
        gap8,
      ],
    ]);
  }

  static List<String> _missing(Recipe r, Set<String> have) => r.needs.where((n) => !have.contains(n)).toList();
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final r = recipe;
    return AppPage(title: r.title, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        Pill(l.servings(r.serves)),
        Pill(r.fire ? l.fireMinutes(r.fireMin) : l.filterNoFire),
        Pill(r.waterMl == 0 ? l.filterNoWater : l.waterMl(r.waterMl)),
      ]),
      gap16,
      SectionLabel(l.ingredients),
      AppCard(child: Text(r.ingredients, style: const TextStyle(fontSize: 16))),
      gap16,
      SectionLabel(l.howToMake),
      StepList(r.steps),
      gap8,
      WarnBox(title: l.canSafety, body: l.canSafetyBody),
    ]);
  }
}
