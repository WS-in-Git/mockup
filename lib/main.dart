import 'package:flutter/material.dart';
import 'dart:math'; // Für die Zufallsfarbengenerierung
import 'package:shared_preferences/shared_preferences.dart'; // Für lokale Speicherung
import 'dart:convert'; // Für JSON-Kodierung und Dekodierung
import 'dart:async'; // Für Timer

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meine Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ), // Primärfarbe auf Rot geändert
      home: const HomeScreen(),
    );
  }
}

// Globale Farbdefinitionen für Kategorien
// Dies macht die Farben für alle Screens zugänglich.
// Nicht mehr 'const', da neue Farben hinzugefügt werden können.
Map<String, Color> _categoryColors = {
  'Alle': Colors.blueGrey, // Eine neutrale Farbe für 'Alle'
  'Obst & Gemüse': Colors.green,
  'Backwaren': Colors.brown,
  'Molkereiprodukte': Colors.lightBlue,
  'Fleisch & Fisch': Colors.red,
  'Grundnahrungsmittel': Colors.orange,
  'Gewürze': Colors.purple,
  'Ohne': Colors.grey, // Kategorie für unkategorisierte Artikel
  'Uncategorized': Colors.grey, // Fallback, falls Kategorie nicht gefunden wird
};

// Vordefinierte Farben für die Palette neuer Kategorien
final List<Color> _predefinedPaletteColors = [
  Colors.blue,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.amber,
  Colors.cyan,
  Colors.deepOrange,
  Colors.lightGreen,
  Colors.lime,
  Colors.brown,
  Colors.deepPurple,
  Colors.deepOrangeAccent,
  Colors.lightGreenAccent,
  Colors.limeAccent,
  Colors.purpleAccent,
];

// Funktion zum Generieren einer zufälligen Farbe für neue Kategorien
Color _generateRandomColor() {
  final Random random = new Random();
  return Color.fromARGB(
    255,
    random.nextInt(200) + 50, // Vermeide zu dunkle/helle Farben
    random.nextInt(200) + 50,
    random.nextInt(200) + 50,
  );
}

// Globale Definition für die kategorisierten Artikel (Masterliste)
// Initialisiert mit Standardartikeln, wird später mit SharedPreferences überschrieben.
Map<String, List<Map<String, dynamic>>> _categorizedItems = Map.from(
  _defaultCategorizedItems,
);

// Standardartikel für die Initialisierung von _categorizedItems
const Map<String, List<Map<String, dynamic>>> _defaultCategorizedItems = {
  'Obst & Gemüse': [
    {
      'name': 'Äpfel',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Tomaten',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Gurken',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Kartoffeln',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Zwiebeln',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Knoblauch',
      'category': 'Obst & Gemüse',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Backwaren': [
    {
      'name': 'Brot',
      'category': 'Backwaren',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Molkereiprodukte': [
    {
      'name': 'Milch',
      'category': 'Molkereiprodukte',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Eier',
      'category': 'Molkereiprodukte',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Käse',
      'category': 'Molkereiprodukte',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Fleisch & Fisch': [
    {
      'name': 'Hähnchen',
      'category': 'Fleisch & Fisch',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Fisch',
      'category': 'Fleisch & Fisch',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Grundnahrungsmittel': [
    {
      'name': 'Nudeln',
      'category': 'Grundnahrungsmittel',
      'isDone': false,
      'source': 'Ohne',
    },
    {
      'name': 'Reis',
      'category': 'Grundnahrungsmittel',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Gewürze': [
    {'name': 'Salz', 'category': 'Gewürze', 'isDone': false, 'source': 'Ohne'},
    {
      'name': 'Pfeffer',
      'category': 'Gewürze',
      'isDone': false,
      'source': 'Ohne',
    },
  ],
  'Ohne': [],
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- START DER _HomeScreenState KLASSE ---

  // Eine Map, die alle Einkaufslisten speichert. Schlüssel: Listenname, Wert: Liste der Artikel.
  // Artikel sind jetzt Map<String, dynamic>, um 'isDone' (bool) zu speichern.
  Map<String, List<Map<String, dynamic>>> _allShoppingLists = {};
  // Der Name der aktuell ausgewählten Einkaufsliste.
  String _currentListName = 'Meine erste Liste';
  // Speichert die zuletzt ausgewählte Kategorie für den SelectionScreen.
  String _lastSelectedCategory = 'Alle';
  // Flag, um den Swipe-Hinweis nur einmal anzuzeigen
  bool _showInitialSwipeHint = false;
  // Flag, um alle Artikel anzuzeigen (inkl. erledigte) oder nur unerledigte
  bool _showAllItems = false; // Default: erledigte ausblenden

  // Liste der verfügbaren Bezugsquellen
  List<String> _allSources = [];

  // Variablen für die "Unlöschen"-Funktion
  Map<String, dynamic>? _lastDeletedItem;
  int? _lastDeletedItemIndex;
  Timer? _undoTimer;

  // Flag, das anzeigt, ob alle Daten geladen wurden
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeData(); // Daten beim Start der App laden und Zustand aktualisieren
  }

  // Initialisiert alle Daten asynchron und aktualisiert den UI-Zustand
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Kategoriefarben laden
    final String? categoryColorsString = prefs.getString('categoryColors');
    if (categoryColorsString != null) {
      final Map<String, dynamic> decodedColors = jsonDecode(
        categoryColorsString,
      );
      _categoryColors = decodedColors.map(
        (key, value) => MapEntry(key, Color(value as int)),
      );
    }
    // Sicherstellen, dass Systemkategorien immer vorhanden sind
    if (!_categoryColors.containsKey('Ohne')) {
      _categoryColors['Ohne'] = Colors.grey;
    }
    if (!_categoryColors.containsKey('Alle')) {
      _categoryColors['Alle'] = Colors.blueGrey;
    }
    if (!_categoryColors.containsKey('Uncategorized')) {
      _categoryColors['Uncategorized'] = Colors.grey;
    }
    debugPrint('Kategoriefarben geladen: $_categoryColors');

    // Bezugsquellen laden
    final List<String>? sourcesList = prefs.getStringList('allSources');
    if (sourcesList != null) {
      Set<String> uniqueSources = Set<String>.from(sourcesList);
      _allSources = uniqueSources.toList();
      _allSources.sort();
    }
    // Sicherstellen, dass 'Ohne' Bezugsquelle immer vorhanden ist
    if (!_allSources.contains('Ohne')) {
      _allSources.insert(0, 'Ohne');
      _allSources.sort();
    }
    debugPrint('Bezugsquellen geladen: $_allSources');

    // Einkaufslisten laden
    final String? shoppingListsString = prefs.getString('allShoppingLists');
    if (shoppingListsString != null) {
      final Map<String, dynamic> decodedLists = jsonDecode(shoppingListsString);
      _allShoppingLists = decodedLists.map((listName, itemsJson) {
        List<Map<String, dynamic>> items = (itemsJson as List).map((itemMap) {
          // Sicherstellen, dass isDone als bool geladen wird, Standardwert false
          final Map<String, dynamic> parsedItem = Map<String, dynamic>.from(
            itemMap,
          );
          parsedItem['isDone'] =
              parsedItem['isDone'] ?? false; // Standardwert für alte Einträge
          // Sicherstellen, dass source geladen wird, Standardwert 'Ohne'
          parsedItem['source'] = parsedItem['source'] ?? 'Ohne';
          return parsedItem;
        }).toList();
        return MapEntry(listName, items);
      });
    } else {
      // Wenn keine Listen vorhanden sind, erstelle eine Standardliste
      _allShoppingLists[_currentListName] = [];
    }
    debugPrint('Einkaufslisten geladen: $_allShoppingLists');

    // Kategorisierte Artikel laden
    final String? categorizedItemsString = prefs.getString('categorizedItems');
    if (categorizedItemsString != null) {
      final Map<String, dynamic> decodedCategorizedItems = jsonDecode(
        categorizedItemsString,
      );
      _categorizedItems = decodedCategorizedItems.map((category, itemsJson) {
        List<Map<String, dynamic>> items = (itemsJson as List).map((itemMap) {
          final Map<String, dynamic> parsedItem = Map<String, dynamic>.from(
            itemMap,
          );
          parsedItem['isDone'] = parsedItem['isDone'] ?? false;
          parsedItem['source'] = parsedItem['source'] ?? 'Ohne';
          return parsedItem;
        }).toList();
        return MapEntry(category, items);
      });
      debugPrint('Kategorisierte Artikel geladen: $_categorizedItems');
    } else {
      // Wenn nicht gefunden, _categorizedItems hat bereits Standardwerte (globale Variable).
      debugPrint(
        'Kategorisierte Artikel mit Standardwerten initialisiert (globale Variable).',
      );
    }
    // Sicherstellen, dass 'Ohne' Kategorie immer in _categorizedItems vorhanden ist
    if (!_categorizedItems.containsKey('Ohne')) {
      _categorizedItems['Ohne'] = [];
    }

    // Aktuellen Listennamen laden
    final String? currentListName = prefs.getString('currentListName');
    if (currentListName != null &&
        _allShoppingLists.containsKey(currentListName)) {
      _currentListName = currentListName;
    } else if (_allShoppingLists.isNotEmpty) {
      _currentListName = _allShoppingLists.keys.first;
    } else {
      // Dieser Fall sollte idealerweise nicht eintreten, wenn _allShoppingLists oben initialisiert wird.
      _currentListName = 'Meine erste Liste';
      _allShoppingLists[_currentListName] =
          []; // Sicherstellen, dass die Liste existiert
    }
    debugPrint('Aktuelle Liste nach Laden: $_currentListName');

    // Prüfen, ob der Swipe-Hinweis schon einmal angezeigt wurde
    final bool hasShownSwipeHint = prefs.getBool('hasShownSwipeHint') ?? false;
    if (!hasShownSwipeHint) {
      _showInitialSwipeHint = true;
      await prefs.setBool('hasShownSwipeHint', true); // Als angezeigt markieren
    }

    // Nachdem alle Daten geladen sind, den UI-Zustand aktualisieren
    setState(() {
      _isDataLoaded = true;
      // Zeige den Hinweis nach dem ersten Frame, wenn er noch nicht angezeigt wurde
      if (_showInitialSwipeHint) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tipp: Wische einen Artikel nach rechts zum Erledigen/Unerledigen oder nach links zum Löschen.',
              ),
              duration: Duration(seconds: 4), // Hinweis für 4 Sekunden anzeigen
            ),
          );
        });
      }
    });
  }

  // Speichern der Daten in SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Kategoriefarben speichern (als ARGB int)
    final Map<String, int> colorsToSave = _categoryColors.map(
      (key, value) => MapEntry(key, value.value),
    );
    await prefs.setString('categoryColors', jsonEncode(colorsToSave));
    debugPrint('Kategoriefarben gespeichert.');

    // Bezugsquellen speichern
    // Ensure uniqueness before saving to SharedPreferences
    Set<String> uniqueSources = Set<String>.from(_allSources);
    await prefs.setStringList('allSources', uniqueSources.toList());
    debugPrint('Bezugsquellen gespeichert.');

    // Einkaufslisten speichern
    // JSON Encode kann Map<String, dynamic> direkt handhaben
    final Map<String, dynamic> listsToSave = _allShoppingLists;
    await prefs.setString('allShoppingLists', jsonEncode(listsToSave));
    debugPrint('Einkaufslisten gespeichert.');

    // Kategorisierte Artikel speichern
    await prefs.setString('categorizedItems', jsonEncode(_categorizedItems));
    debugPrint('Kategorisierte Artikel gespeichert.');

    // Aktuellen Listennamen speichern
    await prefs.setString('currentListName', _currentListName);
    debugPrint('Aktueller Listenname gespeichert: $_currentListName');
  }

  // Methode zum Hinzufügen eines Artikels zur aktuellen Liste
  // itemData enthält jetzt auch 'isDone' (als String 'false' vom SelectionScreen)
  void _addItemToCurrentList(Map<String, dynamic> itemData) {
    setState(() {
      // Sicherstellen, dass isDone als bool gespeichert wird
      itemData['isDone'] =
          itemData['isDone'] == 'true'; // Konvertiere String zu bool
      _allShoppingLists[_currentListName]!.add(itemData);
      _saveData(); // Daten nach Änderung speichern
    });
  }

  // Methode zum Entfernen eines Artikels aus der aktuellen Liste
  void _removeItemFromCurrentList(Map<String, dynamic> itemToRemove) {
    setState(() {
      _allShoppingLists[_currentListName]!.removeWhere(
        (item) =>
            item['name'] == itemToRemove['name'] &&
            item['category'] == itemToRemove['category'],
      ); // isDone nicht für Vergleich nutzen
      _saveData(); // Daten nach Änderung speichern
    });
  }

  // Methode zum Umschalten des 'isDone'-Status eines Artikels
  void _toggleItemDoneStatus(Map<String, dynamic> item) {
    setState(() {
      item['isDone'] = !(item['isDone'] as bool); // Status umkehren
      _saveData(); // Daten nach Änderung speichern
    });
  }

  // Methode zum Wiederherstellen des zuletzt gelöschten Artikels
  void _restoreLastDeletedItem() {
    if (_lastDeletedItem != null && _lastDeletedItemIndex != null) {
      setState(() {
        // Sicherstellen, dass die Liste existiert, falls nicht, erstelle sie
        if (!_allShoppingLists.containsKey(_currentListName)) {
          _allShoppingLists[_currentListName] = [];
        }
        // Füge den Artikel an seiner ursprünglichen Position ein, wenn möglich, sonst am Ende
        if (_lastDeletedItemIndex! <=
            _allShoppingLists[_currentListName]!.length) {
          _allShoppingLists[_currentListName]!.insert(
            _lastDeletedItemIndex!,
            _lastDeletedItem!,
          );
        } else {
          _allShoppingLists[_currentListName]!.add(_lastDeletedItem!);
        }
        _lastDeletedItem = null;
        _lastDeletedItemIndex = null;
        _undoTimer?.cancel(); // Timer abbrechen, wenn Undo gedrückt wird
        _saveData(); // Wiederhergestellte Daten speichern
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 500),
          content: Text('Artikel wiederhergestellt.'),
        ),
      );
    }
  }

  // Methode zum Hinzufügen einer neuen Einkaufsliste
  void _addNewShoppingList(String listName) {
    if (listName.trim().isEmpty || _allShoppingLists.containsKey(listName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text(
            listName.trim().isEmpty
                ? 'Listenname darf nicht leer sein.'
                : 'Liste "$listName" existiert bereits.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _allShoppingLists[listName] = [];
      _currentListName = listName; // Neue Liste direkt auswählen
      _saveData(); // Daten nach Änderung speichern
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          content: Text('Liste "$listName" erstellt.'),
        ),
      );
    });
    // Navigator.pop(context); // Drawer schließen - removed, as this is now called from ListManagementScreen
  }

  // Methode zum Löschen einer Einkaufsliste
  void _deleteShoppingList(String listName) {
    if (_allShoppingLists.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1500),
          content: Text('Die letzte Liste kann nicht gelöscht werden.'),
        ),
      );
      return;
    }
    setState(() {
      _allShoppingLists.remove(listName);
      if (_currentListName == listName) {
        _currentListName =
            _allShoppingLists.keys.first; // Erste verbleibende Liste auswählen
      }
      _saveData(); // Daten nach Änderung speichern
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          content: Text('Liste "$listName" gelöscht.'),
        ),
      );
    });
    // Navigator.pop(context); // Drawer schließen - removed, as this is now called from ListManagementScreen
  }

  // Methode zum Umbenennen einer Einkaufsliste
  void _renameShoppingList(String oldName, String newName) {
    if (oldName == newName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Der Name wurde nicht geändert.'),
        ),
      );
      return;
    }
    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Listenname darf nicht leer sein.'),
        ),
      );
      return;
    }
    if (_allShoppingLists.containsKey(newName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('Liste "$newName" existiert bereits.'),
        ),
      );
      return;
    }

    setState(() {
      final List<Map<String, dynamic>> items = _allShoppingLists[oldName]!;
      _allShoppingLists.remove(oldName);
      _allShoppingLists[newName] = items;

      if (_currentListName == oldName) {
        _currentListName = newName;
      }
      _saveData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          content: Text('Liste umbenannt zu "$newName".'),
        ),
      );
    });
  }

  // Methode zum Hinzufügen einer neuen Bezugsquelle
  void _addNewSource(String sourceName) {
    if (sourceName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Bezugsquellenname darf nicht leer sein.'),
        ),
      );
      return;
    }
    setState(() {
      // Use a Set to add and ensure uniqueness, then convert back to list
      Set<String> tempSources = Set<String>.from(_allSources);
      if (!tempSources.contains(sourceName)) {
        tempSources.add(sourceName);
        _allSources = tempSources.toList();
        _allSources.sort(); // Keep sorted
        _saveData(); // Daten nach Änderung speichern
        debugPrint('Neue Bezugsquelle hinzugefügt: $sourceName');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1000),
            content: Text('Bezugsquelle "$sourceName" existiert bereits.'),
          ),
        );
      }
    });
  }

  // Methode zum Löschen einer Bezugsquelle
  void _deleteSource(String sourceName) {
    setState(() {
      _allSources = List.from(_allSources)
        ..remove(sourceName); // Erstellt eine neue Liste
      // Update all items in all shopping lists that used the deleted source
      _allShoppingLists.forEach((listName, items) {
        for (var item in items) {
          if (item['source'] == sourceName) {
            item['source'] = 'Ohne'; // Assign to 'Ohne'
          }
        }
      });
      _saveData(); // Daten nach Änderung speichern
      debugPrint('Bezugsquelle gelöscht: $sourceName');
    });
  }

  // Methode zum Umbenennen einer Bezugsquelle
  void _renameSource(String oldName, String newName) {
    if (oldName == newName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Der Name wurde nicht geändert.'),
        ),
      );
      return;
    }
    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Bezugsquellenname darf nicht leer sein.'),
        ),
      );
      return;
    }
    if (_allSources.contains(newName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('Bezugsquelle "$newName" existiert bereits.'),
        ),
      );
      return;
    }

    setState(() {
      final int index = _allSources.indexOf(oldName);
      if (index != -1) {
        _allSources[index] = newName;

        // Update all items in all shopping lists that use the old source name
        _allShoppingLists.forEach((listName, items) {
          for (var item in items) {
            if (item['source'] == oldName) {
              item['source'] = newName;
            }
          }
        });

        _saveData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 500),
            content: Text('Bezugsquelle umbenannt zu "$newName".'),
          ),
        );
      }
    });
  }

  // System-defined categories that cannot be deleted or renamed from the master list
  final List<String> _systemCategories = ['Alle', 'Ohne', 'Uncategorized'];

  // Methode zum Hinzufügen einer neuen Kategorie (aus CategoryManagementScreen)
  void _addNewCategory(String categoryName, {Color? categoryColor}) {
    setState(() {
      if (!_categoryColors.containsKey(categoryName)) {
        _categoryColors[categoryName] = categoryColor ?? _generateRandomColor();
        _saveData(); // Kategoriefarben speichern
        debugPrint(
          'Neue Kategorie hinzugefügt: $categoryName mit Farbe ${_categoryColors[categoryName]}',
        );
      } else {
        debugPrint('Kategorie "$categoryName" existiert bereits.');
      }
    });
  }

  // Methode zum Löschen einer Kategorie (aus CategoryManagementScreen)
  void _deleteCategory(String categoryName) {
    setState(() {
      _categoryColors.remove(categoryName);
      // Alle Artikel, die diese Kategorie hatten, der Kategorie "Ohne" zuweisen
      _allShoppingLists.forEach((listName, items) {
        for (var item in items) {
          if (item['category'] == categoryName) {
            item['category'] = 'Ohne';
          }
        }
      });
      _saveData(); // Änderungen speichern
      debugPrint('Kategorie gelöscht: $categoryName');
    });
  }

  // Methode zum Umbenennen einer Kategorie (aus CategoryManagementScreen)
  void _renameCategory(String oldName, String newName, Color? newColor) {
    if (oldName == newName &&
        (newColor == null || _categoryColors[oldName] == newColor)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Der Name oder die Farbe wurde nicht geändert.'),
        ),
      );
      return;
    }
    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('Kategoriename darf nicht leer sein.'),
        ),
      );
      return;
    }
    if (_categoryColors.containsKey(newName) && newName != oldName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('Kategorie "$newName" existiert bereits.'),
        ),
      );
      return;
    }

    setState(() {
      // Kategorie-Farbe aktualisieren
      if (newColor != null) {
        _categoryColors[newName] = newColor;
      } else if (_categoryColors.containsKey(oldName)) {
        _categoryColors[newName] =
            _categoryColors[oldName]!; // Alte Farbe beibehalten, wenn keine neue Farbe ausgewählt
      } else {
        _categoryColors[newName] =
            _generateRandomColor(); // Zufällige Farbe zuweisen, wenn keine alte Farbe und keine neue ausgewählt
      }

      if (oldName != newName) {
        _categoryColors.remove(
          oldName,
        ); // Alten Eintrag entfernen, wenn Name geändert

        // Alle Artikel in allen Einkaufslisten aktualisieren, die den alten Kategorienamen verwenden
        _allShoppingLists.forEach((listName, items) {
          for (var item in items) {
            if (item['category'] == oldName) {
              item['category'] = newName;
            }
          }
        });
      }

      _saveData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          content: Text('Kategorie umbenannt zu "$newName".'),
        ),
      );
    });
  }

  // Dialog zum Umbenennen einer Einkaufsliste (wird jetzt von ListManagementScreen aufgerufen)
  Future<void> _showRenameListDialog(String oldListName) async {
    TextEditingController _renameController = TextEditingController(
      text: oldListName,
    );
    String?
    newListName; // Temporäre Variable, um den Wert des Textfeldes zu speichern

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Liste umbenennen'),
          content: TextField(
            controller: _renameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Neuer Listenname'),
            onChanged: (value) {
              newListName =
                  value; // Aktualisiere die temporäre Variable bei jeder Änderung
            },
            onSubmitted: (value) {
              // Ermöglicht das Umbenennen durch Drücken von Enter
              if (value.trim().isNotEmpty) {
                _renameShoppingList(oldListName, value.trim());
                Navigator.of(context).pop(); // Dialog schließen
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
              },
            ),
            TextButton(
              child: const Text('Umbenennen'),
              onPressed: () {
                // Verwende den Wert aus der temporären Variable oder dem Controller, falls onChanged nicht ausgelöst wurde
                final String nameToUse =
                    newListName?.trim() ?? _renameController.text.trim();
                if (nameToUse.isNotEmpty) {
                  _renameShoppingList(oldListName, nameToUse);
                  Navigator.of(context).pop(); // Dialog schließen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 1000),
                      content: Text('Listenname darf nicht leer sein.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog zum Erstellen einer neuen Einkaufsliste (wird jetzt von ListManagementScreen aufgerufen)
  Future<void> _showCreateNewListDialog() async {
    TextEditingController _listNameController =
        TextEditingController(); // Korrekter Controller für diesen Dialog
    String?
    newListName; // Temporäre Variable, um den Wert des Textfeldes zu speichern

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neue Einkaufsliste'),
          content: TextField(
            controller:
                _listNameController, // Verwende den korrekten Controller
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Listenname'),
            onChanged: (value) {
              newListName =
                  value; // Aktualisiere die temporäre Variable bei jeder Änderung
            },
            onSubmitted: (value) {
              // Ermöglicht das Hinzufügen durch Drücken von Enter
              if (value.trim().isNotEmpty) {
                _addNewShoppingList(value.trim());
                Navigator.of(context).pop();
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Erstellen'),
              onPressed: () {
                if (newListName != null && newListName!.trim().isNotEmpty) {
                  _addNewShoppingList(newListName!.trim());
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listenname darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Diese Methode wird aufgerufen, wenn der Plus-Knopf gedrückt wird.
  void _navigateToAddItemScreen() async {
    // Übergebe die _addItemToCurrentList Funktion an den SelectionScreen
    final String? returnedFilterCategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectionScreen(
          initialCategory: _lastSelectedCategory,
          existingShoppingListItems: _allShoppingLists[_currentListName]!,
          onItemAdded: (itemData) {
            _addItemToCurrentList(itemData);
          },
          availableSources: _allSources, // Pass sources to SelectionScreen
          onNewSourceCreated: _addNewSource, // Pass source creation callback
          onSourceDeleted: _deleteSource, // Pass source delete callback
          onSourceRenamed: _renameSource, // Pass source rename callback
          onNewCategoryCreated: _addNewCategory, // Pass HomeScreen's method
          onCategoryDeleted: _deleteCategory, // Pass HomeScreen's method
          onCategoryRenamed: _renameCategory, // Pass HomeScreen's method
          onCategorizedItemsUpdated:
              _saveData, // Pass callback to save categorized items
        ),
      ),
    );

    // Aktualisiere die zuletzt ausgewählte Kategorie, wenn der Benutzer zurückkehrt
    if (returnedFilterCategory != null) {
      _lastSelectedCategory = returnedFilterCategory;
    }
  }

  // Dialog zum Ändern der Bezugsquelle eines Artikels im HomeScreen
  Future<void> _showSourceSelectionDialogForHome(
    Map<String, dynamic> item,
  ) async {
    String? currentSelectedItemSource = item['source'];

    final String? resultSource = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return _SourceSelectionBottomSheet(
          availableSources:
              _allSources, // Use _allSources from HomeScreen state
          onNewSourceCreated: _addNewSource, // Use HomeScreen's _addNewSource
          initialSource: currentSelectedItemSource!,
          onSourceSelected: (selectedSource) {
            Navigator.pop(context, selectedSource); // Return selected source
          },
        );
      },
    );

    if (resultSource != null) {
      setState(() {
        item['source'] = resultSource; // Update the source for the item
        _saveData(); // Save the updated item
      });
    }
  }

  // Methode zum Navigieren durch die Listen per Swipe
  void _navigateThroughLists(DragEndDetails details) {
    if (_allShoppingLists.isEmpty)
      return; // Nichts zu tun, wenn keine Listen vorhanden sind

    List<String> listNames = _allShoppingLists.keys.toList();
    int currentIndex = listNames.indexOf(_currentListName);

    if (currentIndex == -1) {
      // Sollte nicht passieren, aber zur Sicherheit
      return;
    }

    setState(() {
      if (details.primaryVelocity! < 0) {
        // Swipe von rechts nach links (nächste Liste)
        currentIndex = (currentIndex + 1) % listNames.length;
      } else if (details.primaryVelocity! > 0) {
        // Swipe von links nach rechts (vorherige Liste)
        currentIndex = (currentIndex - 1 + listNames.length) % listNames.length;
      }
      _currentListName = listNames[currentIndex];
      _saveData(); // Speichere den neuen aktuellen Listennamen
    });
  }

  @override
  Widget build(BuildContext context) {
    // Zeige einen Ladeindikator, wenn die Daten noch nicht geladen sind
    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          toolbarHeight: 48,
          title: const Text('Lade Daten...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(), // Zeige einen Ladekreis an
        ),
      );
    }

    // Überprüfe, ob die aktuelle Liste leer ist
    bool isCurrentListEmpty =
        (_allShoppingLists[_currentListName]?.isEmpty ?? true);
    // Überprüfe, ob alle Artikel erledigt sind (nur relevant, wenn _showAllItems false ist)
    bool allItemsDone = false;
    if (!isCurrentListEmpty) {
      allItemsDone = _allShoppingLists[_currentListName]!.every(
        (item) => item['isDone'] == true,
      );
    }

    Widget bodyContent;

    if (isCurrentListEmpty) {
      // Fall 1: Liste ist komplett leer
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Die Liste "$_currentListName" ist noch leer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToAddItemScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Hintergrundfarbe Rot
                shape: const CircleBorder(), // Runde Form
                padding: const EdgeInsets.all(
                  20,
                ), // Innenabstand für die Größe des Kreises
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ), // Weißes Plus-Icon
            ),
          ],
        ),
      );
    } else if (!_showAllItems && allItemsDone) {
      // Fall 2: Alle Artikel sind erledigt und "erledigte verbergen" ist aktiv
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Alles erledigt!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAllItems =
                      true; // Umschalten, um erledigte Artikel anzuzeigen
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Hintergrundfarbe Rot
                shape: const CircleBorder(), // Runde Form
                padding: const EdgeInsets.all(
                  20,
                ), // Innenabstand für die Größe des Kreises
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 30,
              ), // Weißes Sichtbarkeits-Icon
            ),
          ],
        ),
      );
    } else {
      // Fall 3: Normale Listenanzeige ohne ReorderableListView
      // Group articles by category and sort categories alphabetically (excluding system categories, 'Ohne' last)
      Map<String, List<Map<String, dynamic>>> groupedArticles = {};
      (_allShoppingLists[_currentListName] ?? []).forEach((item) {
        final category = item['category'] ?? 'Ohne';
        if (!_showAllItems && (item['isDone'] as bool)) {
          return; // Skip if item is done and not showing all
        }
        if (!groupedArticles.containsKey(category)) {
          groupedArticles[category] = [];
        }
        groupedArticles[category]!.add(item);
      });

      List<String> sortedCategories = groupedArticles.keys.toList();
      // Sort categories alphabetically, but ensure 'Ohne' is always at the end
      sortedCategories.sort((a, b) {
        if (a == 'Ohne') return 1;
        if (b == 'Ohne') return -1;
        return a.compareTo(b);
      });

      // Sort items within each category alphabetically
      groupedArticles.values.forEach((items) {
        items.sort((a, b) => a['name'].compareTo(b['name']));
      });

      List<Widget> listWidgets = [];
      for (String categoryName in sortedCategories) {
        final categoryColor = _categoryColors[categoryName] ?? Colors.grey;
        final articlesInThisCategory = groupedArticles[categoryName]!;

        listWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 14.4,
                fontWeight: FontWeight.bold,
                color: categoryColor,
              ),
            ),
          ),
        );

        for (var item in articlesInThisCategory) {
          final bool isDone = item['isDone'] as bool;
          final String itemSource = item['source'] ?? 'Ohne';

          listWidgets.add(
            Dismissible(
              key: Key(item['name']! + item['category']!), // Stable key
              direction: DismissDirection.horizontal,
              background: Container(
                color: isDone ? Colors.grey : Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(
                  isDone ? Icons.undo : Icons.check,
                  color: Colors.white,
                  size: 22.5,
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 22.5,
                ),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  final List<Map<String, dynamic>> currentListItems =
                      _allShoppingLists[_currentListName]!;
                  final int originalIndex = currentListItems.indexOf(item);

                  setState(() {
                    _lastDeletedItem = Map<String, dynamic>.from(item);
                    _lastDeletedItemIndex = originalIndex;
                    _removeItemFromCurrentList(item);
                  });

                  _undoTimer?.cancel();
                  _undoTimer = Timer(const Duration(seconds: 5), () {
                    if (mounted) {
                      setState(() {
                        _lastDeletedItem = null;
                        _lastDeletedItemIndex = null;
                      });
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 500),
                      content: Text('Artikel "${item['name']}" gelöscht.'),
                    ),
                  );
                }
              },
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  _toggleItemDoneStatus(item);
                  return _showAllItems ? false : (item['isDone'] as bool);
                }
                return true;
              },
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2.0,
                ),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: categoryColor, width: 1.5),
                ),
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    _toggleItemDoneStatus(item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0.5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['name']!,
                                style: TextStyle(
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.bold,
                                  color: isDone ? Colors.grey : Colors.black,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showSourceSelectionDialogForHome(item);
                                },
                                child: Text(
                                  'Bezugsquelle: $itemSource',
                                  style: TextStyle(
                                    fontSize: 9.6,
                                    color: isDone
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Checkbox(
                            value: isDone,
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: isDone ? Colors.green : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            onChanged: (bool? newValue) {
                              _toggleItemDoneStatus(item);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      bodyContent = ListView(children: listWidgets);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        title: GestureDetector(
          // Wrapped the Text with GestureDetector
          onTap: () async {
            // Navigate to ListManagementScreen
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListManagementScreen(
                  allShoppingLists: _allShoppingLists,
                  currentListName: _currentListName,
                  onRenameList: _renameShoppingList,
                  onDeleteList: _deleteShoppingList,
                  onCreateNewList: _addNewShoppingList,
                  onSaveData: _saveData,
                  onListSelected: (listName) {
                    setState(() {
                      _currentListName = listName;
                    });
                    _saveData();
                  },
                ),
              ),
            );
            // After returning from ListManagementScreen, re-initialize data to ensure currentListName is updated
            _initializeData();
          },
          onHorizontalDragEnd: _navigateThroughLists, // Added swipe gesture
          child: Text(
            _currentListName,
          ), // Zeigt den Namen der aktuellen Liste an
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Einkaufslisten',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ), // Schriftgröße reduziert
                    ),
                    const SizedBox(height: 4), // Höhe reduziert
                    Text(
                      'Aktuell: $_currentListName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ), // Schriftgröße reduziert
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Neuer ListTile für "Listen verwalten"
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.list_alt, size: 15),
                    title: const Text(
                      'Listen verwalten',
                      style: TextStyle(fontSize: 15),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Drawer schließen
                      // Navigiere zum ListManagementScreen und übergebe die benötigten Callbacks und Daten
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListManagementScreen(
                            allShoppingLists: _allShoppingLists,
                            currentListName: _currentListName,
                            onRenameList: _renameShoppingList,
                            onDeleteList: _deleteShoppingList,
                            onCreateNewList: _addNewShoppingList,
                            onSaveData:
                                _saveData, // Pass the save data callback
                            onListSelected: (listName) {
                              // Callback vom ListManagementScreen
                              // Aktualisiere den Zustand hier im HomeScreen
                              setState(() {
                                _currentListName = listName;
                              });
                              _saveData(); // Speichere den neuen aktuellen Listennamen sofort
                            },
                          ),
                        ),
                      );
                      // Nach Rückkehr vom ListManagementScreen:
                      // Der HomeScreen sollte bereits durch den setState im onListSelected-Callback aktualisiert sein.
                      // Ein erneutes _initializeData() ist nicht unbedingt notwendig, aber schadet nicht.
                      // Ich belasse es hier zur Sicherheit, falls andere Daten auch aktualisiert werden müssen.
                      _initializeData();
                    },
                  ),
                  const Divider(height: 8), // Höhe reduziert
                  ListTile(
                    dense: true, // Macht das ListTile kompakter
                    visualDensity:
                        VisualDensity.compact, // Macht das ListTile kompakter
                    leading: const Icon(
                      Icons.article,
                      size: 15,
                    ), // Größe auf 75% reduziert
                    title: const Text(
                      'Artikel verwalten',
                      style: TextStyle(fontSize: 15),
                    ), // Schriftgröße reduziert
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleManagementScreen(
                            onNewCategoryCreated: _addNewCategory,
                            onCategoryDeleted: _deleteCategory,
                            onCategoryRenamed: _renameCategory,
                            availableSources: _allSources,
                            onNewSourceCreated: _addNewSource,
                            onSourceDeleted: _deleteSource,
                            onSourceRenamed: _renameSource,
                            onCategorizedItemsUpdated:
                                _saveData, // Pass callback to save categorized items
                          ),
                        ),
                      );
                      _initializeData(); // Daten nach Rückkehr aus der Artikelverwaltung neu laden
                    },
                  ),
                  const Divider(height: 8), // Höhe reduziert
                  ListTile(
                    dense: true, // Macht das ListTile kompakter
                    visualDensity:
                        VisualDensity.compact, // Macht das ListTile kompakter
                    leading: const Icon(
                      Icons.category,
                      size: 15,
                    ), // Größe auf 75% reduziert
                    title: const Text(
                      'Kategorien verwalten',
                      style: TextStyle(fontSize: 15),
                    ), // Schriftgröße reduziert
                    onTap: () async {
                      Navigator.pop(context); // Drawer schließen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryManagementScreen(
                            availableCategories: _categoryColors.keys.toList(),
                            onNewCategoryCreated: _addNewCategory,
                            onCategoryDeleted: _deleteCategory,
                            onCategoryRenamed: _renameCategory,
                          ),
                        ),
                      );
                      _initializeData(); // Daten nach Rückkehr aus der Kategorienverwaltung neu laden
                    },
                  ),
                  const Divider(height: 8), // Höhe reduziert
                  ListTile(
                    dense: true, // Macht das ListTile kompakter
                    visualDensity:
                        VisualDensity.compact, // Macht das ListTile kompakter
                    leading: const Icon(
                      Icons.store,
                      size: 15,
                    ), // Größe auf 75% reduziert
                    title: const Text(
                      'Bezugsquellen verwalten',
                      style: TextStyle(fontSize: 15),
                    ), // Schriftgröße reduziert
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SourceManagementScreen(
                            availableSources: _allSources,
                            onNewSourceCreated: _addNewSource,
                            onSourceDeleted:
                                _deleteSource, // Pass delete callback
                            onSourceRenamed:
                                _renameSource, // Pass rename callback
                          ),
                        ),
                      );
                      _initializeData(); // Daten nach Rückkehr aus der Bezugsquellenverwaltung neu laden
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: bodyContent, // Hier wird der dynamische Inhalt verwendet
      // Neue BottomAppBar
      bottomNavigationBar: BottomAppBar(
        color: Colors.red, // Farbe der Leiste
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Icons links ausrichten
          children: <Widget>[
            // Einzelner Filter-Button
            IconButton(
              icon: Icon(
                _showAllItems
                    ? Icons.visibility
                    : Icons.visibility_off, // Icon wechselt je nach Zustand
                color: Colors.white,
                size: 21, // Größe auf 75% reduziert
              ),
              onPressed: () {
                setState(() {
                  _showAllItems = !_showAllItems; // Zustand umschalten
                });
              },
              tooltip: _showAllItems
                  ? 'Erledigte Artikel ausblenden'
                  : 'Alle Artikel anzeigen', // Tooltip wechselt
            ),
            // Undo-Button (nur sichtbar, wenn ein Artikel gelöscht wurde)
            if (_lastDeletedItem != null)
              IconButton(
                icon: const Icon(
                  Icons.undo,
                  color: Colors.white,
                  size: 21,
                ), // Größe auf 75% reduziert
                onPressed: _restoreLastDeletedItem,
                tooltip: 'Gelöschten Artikel wiederherstellen',
              ),
            const Spacer(), // Schiebt die folgenden Widgets nach rechts
            // "Artikel hinzufügen"-Button
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed:
                  _navigateToAddItemScreen, // Ruft die gleiche Funktion wie der FAB auf
              tooltip: 'Element hinzufügen',
            ),
          ],
        ),
      ),
    );
  }
} // --- ENDE DER _HomeScreenState KLASSE ---

// Der SelectionScreen, auf dem Elemente ausgewählt werden können.
class SelectionScreen extends StatefulWidget {
  final String initialCategory;
  final List<Map<String, dynamic>>
  existingShoppingListItems; // Aktualisiert auf dynamic
  final Function(Map<String, dynamic> itemData)
  onItemAdded; // Aktualisiert auf dynamic
  final List<String> availableSources; // New: Pass available sources
  final Function(String sourceName)
  onNewSourceCreated; // New: Pass source creation callback
  final Function(String sourceName)
  onSourceDeleted; // New: Pass source deletion callback
  final Function(String oldName, String newName)
  onSourceRenamed; // New: Pass source rename callback
  final Function(String categoryName, {Color? categoryColor})
  onNewCategoryCreated; // New: Pass category creation callback
  final Function(String categoryName)
  onCategoryDeleted; // New: Pass category deletion callback
  final Function(String oldName, String newName, Color? newColor)
  onCategoryRenamed; // New: Pass category rename callback
  final VoidCallback
  onCategorizedItemsUpdated; // New: Callback to notify HomeScreen about changes to _categorizedItems

  const SelectionScreen({
    super.key,
    this.initialCategory = 'Alle',
    required this.existingShoppingListItems,
    required this.onItemAdded,
    required this.availableSources, // Require new parameter
    required this.onNewSourceCreated, // Require new parameter
    required this.onSourceDeleted, // Require new parameter
    required this.onSourceRenamed, // Require new parameter
    required this.onNewCategoryCreated, // Require new parameter
    required this.onCategoryDeleted, // Require new parameter
    required this.onCategoryRenamed, // Require new parameter
    required this.onCategorizedItemsUpdated, // Require new parameter
  });

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen>
    with SingleTickerProviderStateMixin {
  // _categorizedItems ist jetzt global definiert und wird nicht mehr hier verwaltet.

  String? _selectedCategory; // Changed to nullable
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    debugPrint(
      'SelectionScreen: Initial geladen mit Kategorie: $_selectedCategory',
    );
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });

    // Initialize AnimationController for the "Alle anzeigen" text
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Animation duration
    );

    // Define the color animation (fading between dark blue and white)
    _colorAnimation = ColorTween(
      begin: Colors.blue.shade800, // Dark blue
      end: Colors.white, // White
    ).animate(_animationController);

    // Start repeating the animation if a specific category is already selected
    if (_selectedCategory != 'Alle') {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Control animation based on _selectedCategory
    if (_selectedCategory != 'Alle' && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (_selectedCategory == 'Alle' &&
        _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'Alle') {
      List<Map<String, dynamic>> allItems = [];
      _categorizedItems.forEach((category, items) {
        if (category != 'Alle') {
          allItems.addAll(items);
        }
      });
      allItems.sort((a, b) {
        final categoryA = a['category'] ?? 'Uncategorized';
        final categoryB = b['category'] ?? 'Uncategorized';
        return categoryA.compareTo(categoryB);
      });
      return allItems;
    }
    return _categorizedItems[_selectedCategory] ?? [];
  }

  void _scrollToSelectedCategory() {
    if (_selectedCategory != 'Alle') {
      final List<String> scrollableCategories = _categorizedItems.keys
          .where((k) => k != 'Alle')
          .toList();
      final int selectedIndex = scrollableCategories.indexOf(
        _selectedCategory!,
      ); // Use ! here as it's checked above

      if (selectedIndex != -1) {
        const double estimatedButtonWidth = 120.0;
        final double offset = selectedIndex * estimatedButtonWidth;
        final double maxScrollExtent =
            _scrollController.position.maxScrollExtent;
        final double targetOffset = offset.clamp(0.0, maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Color _getButtonBackgroundColor(
    Color baseColor,
    bool isSelected,
    String categoryName,
  ) {
    if (isSelected) {
      return baseColor;
    } else {
      if (categoryName == 'Alle') {
        return HSLColor.fromColor(
          baseColor,
        ).withSaturation(0.0).withLightness(0.9).toColor();
      } else {
        return HSLColor.fromColor(
          baseColor,
        ).withSaturation(0.2).withLightness(0.75).toColor();
      }
    }
  }

  Color _getButtonForegroundColor(bool isSelected) {
    if (isSelected) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  void _addNewArticle(String name, String category, String source) {
    setState(() {
      if (!_categorizedItems.containsKey(category)) {
        _categorizedItems[category] = [];
      }
      // Neuer Artikel mit isDone: false und source
      _categorizedItems[category]!.add({
        'name': name,
        'category': category,
        'isDone': false,
        'source': source,
      });
      debugPrint(
        'Neuer Artikel hinzugefügt: $name in Kategorie $category von $source',
      );
      widget
          .onCategorizedItemsUpdated(); // Notify HomeScreen to save global _categorizedItems
    });
  }

  void _addNewCategory(String categoryName, {Color? categoryColor}) {
    setState(() {
      if (!_categorizedItems.containsKey(categoryName)) {
        _categorizedItems[categoryName] = [];
        _categoryColors[categoryName] = categoryColor ?? _generateRandomColor();
        debugPrint(
          'Neue Kategorie hinzugefügt: $categoryName mit Farbe ${_categoryColors[categoryName]}',
        );
        _selectedCategory = categoryName;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory();
        });
      } else {
        debugPrint('Kategorie "$categoryName" existiert bereits.');
      }
    });
  }

  // Dialog zum Ändern der Bezugsquelle eines Artikels im SelectionScreen
  Future<void> _showSourceSelectionDialog(Map<String, dynamic> item) async {
    String? currentSelectedItemSource = item['source'];

    final String? resultSource = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return _SourceSelectionBottomSheet(
          availableSources: widget.availableSources,
          onNewSourceCreated: widget.onNewSourceCreated,
          initialSource: currentSelectedItemSource!,
          onSourceSelected: (selectedSource) {
            Navigator.pop(context, selectedSource); // Return selected source
          },
        );
      },
    );

    if (resultSource != null) {
      setState(() {
        item['source'] = resultSource; // Update the source for the item
      });
    }
  }

  List<Widget> _buildSelectionListItems() {
    List<Widget> widgets = [];
    String? currentCategory = '';

    for (int i = 0; i < _filteredItems.length; i++) {
      final item = _filteredItems[i];
      final itemCategory = item['category'] ?? 'Uncategorized';
      final itemColor = _categoryColors[itemCategory] ?? Colors.grey;
      final String itemSource =
          item['source'] ?? 'Ohne'; // Get source for display

      // Überprüfe, ob der Artikel bereits in der Einkaufsliste ist
      // Fürs Ausgrauen hier nur prüfen, ob der Name und die Kategorie übereinstimmen.
      bool isDuplicate = widget.existingShoppingListItems.any(
        (existingItem) =>
            existingItem['name'] == item['name'] &&
            existingItem['category'] == itemCategory,
      );

      // Füge einen Kategorie-Header hinzu, wenn sich die Kategorie ändert und "Alle" ausgewählt ist
      if (_selectedCategory == 'Alle' && itemCategory != currentCategory) {
        widgets.add(
          InkWell(
            onTap: () {
              debugPrint(
                'SelectionScreen Kategorie-Überschrift "$itemCategory" getippt. Ändere Filter auf $itemCategory.',
              );
              setState(() {
                _selectedCategory = itemCategory;
                // Start animation when a specific category is selected
                if (_selectedCategory != 'Alle') {
                  _animationController.repeat(reverse: true);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                4,
              ), // Padding zurückgesetzt
              child: Text(
                itemCategory,
                style: TextStyle(
                  fontSize:
                      14.4, // Font-Größe der Kategorienüberschrift auf 80% (18 * 0.8)
                  fontWeight: FontWeight.bold,
                  color: itemColor,
                ),
              ),
            ),
          ),
        );
        currentCategory = itemCategory;
      }

      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2.0,
          ), // Vertical margin set to 2.0
          elevation: 1, // Elevation reduziert
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isDuplicate ? Colors.grey : itemColor,
              width: 1.5,
            ), // Rahmenbreite reduziert
          ),
          color: isDuplicate
              ? Colors.grey[200]
              : Colors.white, // Hintergrundfarbe anpassen
          child: Padding(
            // Add Padding around the custom content
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0.5,
            ), // Abstand nach oben und unten halbiert (was 1.0)
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize
                        .min, // Make column take minimum vertical space
                    children: [
                      Text(
                        item['name']!,
                        style: TextStyle(
                          fontSize:
                              13.2, // Font-Größe des Artikels um 10% größer (12 * 1.1)
                          fontWeight: FontWeight.bold,
                          color: isDuplicate ? Colors.grey[600] : Colors.black,
                          decoration: isDuplicate
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showSourceSelectionDialog(item);
                        },
                        child: Text(
                          'Bezugsquelle: $itemSource',
                          style: TextStyle(
                            fontSize:
                                9.6, // Font-Größe der Bezugsquelle 20% größer (8 * 1.2)
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDuplicate ? Icons.check_circle_outline : Icons.add_circle,
                    color: isDuplicate ? Colors.grey[600] : itemColor,
                    size: 18, // Further reduce icon size
                  ),
                  onPressed:
                      isDuplicate // onPressed deaktivieren, wenn Duplikat
                      ? null
                      : () {
                          debugPrint(
                            'Plus-Knopf für Artikel "${item['name']}" getippt. Füge Artikel hinzu und bleibe auf dem Screen.',
                          );
                          // Artikel mit isDone: false hinzufügen
                          widget.onItemAdded({
                            'name': item['name'],
                            'category': item['category'],
                            'isDone': false,
                            'source': item['source'],
                          });
                          // KEIN Navigator.pop hier, um auf dem SelectionScreen zu bleiben
                          // setState aufrufen, um den "ausgegrauten" Zustand zu aktualisieren
                          setState(() {});
                        },
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // List<String> categoryButtonKeys = ['Alle']; // This list is no longer needed for buttons
    // categoryButtonKeys.addAll(_categoryColors.keys.where((k) => k != 'Alle').toList()); // Use global _categoryColors

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan, // Farbe der AppBar geändert zu Cyan
        foregroundColor: Colors.white,
        title: const Text('Artikel auswählen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint(
              'Zurück-Pfeil getippt. Rückgabe: Filter: $_selectedCategory.',
            );
            // Gib nur die aktuelle Filterkategorie zurück, da keine Artikel mehr einzeln zurückgegeben werden
            Navigator.pop(context, _selectedCategory);
          },
        ),
        actions: [
          if (_selectedCategory !=
              'Alle') // Only show if a specific category is selected
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Alle';
                  _animationController.stop(); // Stop animation immediately
                  _animationController
                      .reset(); // Reset animation to initial state
                });
              },
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Text(
                    'Alle anzeigen',
                    style: TextStyle(
                      color: _colorAnimation.value,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Removed the Padding containing the Row of category ElevatedButton's
          Expanded(child: ListView(children: _buildSelectionListItems())),
        ],
      ),
      // FloatingActionButton und floatingActionButtonLocation werden entfernt
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // Beibehalten für NewArticleScreen FAB
      floatingActionButton: null, // FAB auf diesem Screen entfernen
      // Neue BottomAppBar für SelectionScreen
      bottomNavigationBar: BottomAppBar(
        color: Colors.cyan, // Farbe der BottomAppBar geändert zu Cyan
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Icons an den Enden platzieren
          children: <Widget>[
            // Icon zum Hinzufügen eines neuen Artikels (ersetzt den FAB)
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed: () async {
                debugPrint(
                  'BottomAppBar "Neuen Artikel hinzufügen" getippt. Navigiere zu Artikel verwalten.',
                );
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleManagementScreen(
                      onNewCategoryCreated: widget.onNewCategoryCreated,
                      onCategoryDeleted: widget.onCategoryDeleted,
                      onCategoryRenamed: widget.onCategoryRenamed,
                      availableSources: widget.availableSources,
                      onNewSourceCreated: widget.onNewSourceCreated,
                      onSourceDeleted: widget.onSourceDeleted,
                      onSourceRenamed: widget.onSourceRenamed,
                      onCategorizedItemsUpdated:
                          widget.onCategorizedItemsUpdated,
                      fromSelectionScreen: true, // New flag
                    ),
                  ),
                );
                // After returning from ArticleManagementScreen, refresh SelectionScreen
                setState(() {});
              },
              tooltip: 'Neuen Artikel hinzufügen',
            ),
            // "Done"-Icon
            IconButton(
              icon: const Icon(
                Icons.check,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed: () {
                debugPrint(
                  'Done-Icon getippt. Rückgabe: Filter: $_selectedCategory.',
                );
                // Gleiche Funktion wie der Zurück-Pfeil in der AppBar
                Navigator.pop(context, _selectedCategory);
              },
              tooltip: 'Auswahl beenden',
            ),
          ],
        ),
      ),
    );
  }
}

// Neuer Screen zur Verwaltung der Bezugsquellen
class SourceManagementScreen extends StatefulWidget {
  final List<String> availableSources;
  final Function(String sourceName) onNewSourceCreated;
  final Function(String sourceName)
  onSourceDeleted; // New: Callback for deleting sources
  final Function(String oldName, String newName)
  onSourceRenamed; // New: Callback for renaming sources

  const SourceManagementScreen({
    super.key,
    required this.availableSources,
    required this.onNewSourceCreated,
    required this.onSourceDeleted, // Require new parameter
    required this.onSourceRenamed, // Require new parameter
  });

  @override
  State<SourceManagementScreen> createState() => _SourceManagementScreenState();
}

class _SourceManagementScreenState extends State<SourceManagementScreen> {
  final TextEditingController _newSourceController = TextEditingController();
  final TextEditingController _editSourceController =
      TextEditingController(); // New controller for editing
  List<String> _currentSources = []; // Internal list for immediate display

  // System-defined sources that cannot be deleted or renamed
  final List<String> _systemSources = ['Ohne'];

  @override
  void initState() {
    super.initState();
    // Ensure uniqueness when initializing _currentSources
    Set<String> uniqueSources = Set<String>.from(widget.availableSources);
    _currentSources = uniqueSources.toList();
    _currentSources.sort(); // Sort for better display
  }

  @override
  void dispose() {
    _newSourceController.dispose();
    _editSourceController.dispose(); // Dispose new controller
    super.dispose();
  }

  // Dialog zum Hinzufügen einer neuen Bezugsquelle
  Future<String?> _showAddSourceDialog() async {
    // Changed return type to Future<String?>
    _newSourceController.clear(); // Textfeld vor jedem Öffnen leeren
    final String? result = await showDialog<String>(
      // Await result from dialog
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neue Bezugsquelle hinzufügen'),
          content: TextField(
            controller: _newSourceController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name der Bezugsquelle',
            ),
            onSubmitted: (value) {
              if (value.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bezugsquellenname darf nicht leer sein.'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
                // Do NOT pop the dialog here, let the user correct
                return;
              }
              final String newSourceName = value.trim();
              if (_currentSources.contains(newSourceName)) {
                // Check against internal _currentSources
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bezugsquelle "$newSourceName" existiert bereits.',
                    ),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
                // Do NOT pop the dialog here, let the user correct
                return;
              }
              // Call parent callback to save the new source globally
              widget.onNewSourceCreated(newSourceName);
              // Update local state for immediate display
              setState(() {
                _currentSources.add(newSourceName);
                _currentSources.sort();
              });
              Navigator.of(
                context,
              ).pop(newSourceName); // Pop the dialog with the new source name
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(null); // Pop the dialog with null on cancel
              },
            ),
            TextButton(
              child: const Text('Hinzufügen'),
              onPressed: () {
                if (_newSourceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bezugsquellenname darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                final String newSourceName = _newSourceController.text.trim();
                if (_currentSources.contains(newSourceName)) {
                  // Check against internal _currentSources
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bezugsquelle "$newSourceName" existiert bereits.',
                      ),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                // Call parent callback to save the new source globally
                widget.onNewSourceCreated(newSourceName);
                // Update local state for immediate display
                setState(() {
                  _currentSources.add(newSourceName); // Update internal list
                  _currentSources.sort(); // Keep sorted
                });
                Navigator.of(
                  context,
                ).pop(newSourceName); // Pop the dialog with the new source name
              },
            ),
          ],
        );
      },
    );
    // This code runs AFTER the AlertDialog is popped.
    // We explicitly do NOT pop the SourceManagementScreen here,
    // so the user stays on this screen after adding a source.
    return result; // Return the result from the dialog
  }

  // Dialog zum Umbenennen einer Bezugsquelle
  Future<void> _showRenameSourceDialog(String oldSourceName, int index) async {
    // Prevent editing system sources
    if (_systemSources.contains(oldSourceName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Systembezugsquelle "$oldSourceName" kann nicht bearbeitet werden.',
          ),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    _editSourceController.text = oldSourceName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bezugsquelle umbenennen'),
          content: TextField(
            controller: _editSourceController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Neuer Bezugsquellenname',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Umbenennen'),
              onPressed: () {
                final String newSourceName = _editSourceController.text.trim();
                if (newSourceName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bezugsquellenname darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                if (newSourceName != oldSourceName &&
                    _currentSources.contains(newSourceName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bezugsquelle "$newSourceName" existiert bereits.',
                      ),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else {
                  widget.onSourceRenamed(oldSourceName, newSourceName);
                  setState(() {
                    _currentSources[index] = newSourceName;
                    _currentSources.sort();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Changed to blue
        foregroundColor: Colors.white,
        title: const Text('Bezugsquellen'), // Titel zu "Bezugsquellen" geändert
        leading: IconButton(
          // Added leading back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              null,
            ); // Return null when simply navigating back
          },
        ),
      ),
      body:
          _currentSources
              .isEmpty // Use internal list for display
          ? const Center(
              child: Text(
                'Noch keine Bezugsquellen vorhanden. Füge neue hinzu!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _currentSources.length, // Use internal list for count
              itemBuilder: (context, index) {
                final source =
                    _currentSources[index]; // Use internal list for item
                final bool isSystemSource = _systemSources.contains(
                  source,
                ); // Check if it's a system source

                return Dismissible(
                  key: Key(source), // Unique key for Dismissible
                  direction: isSystemSource
                      ? DismissDirection.none
                      : DismissDirection
                            .endToStart, // Prevent swipe for system sources
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 22.5,
                    ), // Größe auf 75% reduziert
                  ),
                  confirmDismiss: (direction) async {
                    if (isSystemSource) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Systembezugsquelle "$source" kann nicht gelöscht werden.',
                          ),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                      return false; // Prevent dismissal
                    }
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Bezugsquelle löschen?'),
                          content: Text(
                            'Möchtest du die Bezugsquelle "$source" wirklich löschen? Alle Artikel, die diese Bezugsquelle verwenden, werden der Bezugsquelle "Ohne" zugewiesen.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    return confirm ?? false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      // Swipe to delete
                      widget.onSourceDeleted(source); // Call parent callback
                      setState(() {
                        _currentSources.removeAt(index); // Update local list
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 500),
                          content: Text('Bezugsquelle "$source" gelöscht.'),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2.0,
                    ), // Consistent margin
                    elevation: 1, // Consistent elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: InkWell(
                      // Use InkWell for tap feedback
                      onTap: isSystemSource
                          ? null // Disable tap for system sources
                          : () {
                              _showRenameSourceDialog(
                                source,
                                index,
                              ); // Show rename dialog on tap
                            },
                      child: Padding(
                        // Add Padding for consistent internal spacing
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0.5,
                        ), // Consistent vertical padding
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                source,
                                style: const TextStyle(
                                  fontSize: 15.4,
                                ), // Font not bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        // Changed to BottomAppBar
        color: Colors.blue, // Changed to blue
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the button
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed: () async {
                // Await the result
                // Call _showAddSourceDialog to add a new source
                await _showAddSourceDialog();
                // No Navigator.pop here, so the user stays on this screen
                // _currentSources is already updated via setState in _showAddSourceDialog
              },
              tooltip: 'Neue Bezugsquelle hinzufügen',
            ),
          ],
        ),
      ),
    );
  }
}

// New StatefulWidget for the source selection bottom sheet
class _SourceSelectionBottomSheet extends StatefulWidget {
  final List<String> availableSources;
  final Function(String sourceName) onNewSourceCreated;
  final String initialSource;
  final Function(String selectedSource) onSourceSelected;

  const _SourceSelectionBottomSheet({
    required this.availableSources,
    required this.onNewSourceCreated,
    required this.initialSource,
    required this.onSourceSelected,
  });

  @override
  __SourceSelectionBottomSheetState createState() =>
      __SourceSelectionBottomSheetState();
}

class __SourceSelectionBottomSheetState
    extends State<_SourceSelectionBottomSheet> {
  List<String> _currentSources = []; // Changed to non-late
  String? _selectedSource; // Changed to nullable

  @override
  void initState() {
    super.initState();
    // Ensure uniqueness when initializing _currentSources
    Set<String> uniqueSources = Set<String>.from(widget.availableSources);
    _currentSources = uniqueSources.toList();
    _currentSources.sort(); // Sort for better display
    _selectedSource = widget.initialSource;
  }

  // Dialog zum Hinzufügen einer neuen Bezugsquelle innerhalb des Bottom Sheets
  Future<String?> _showAddSourceDialogForBottomSheet() async {
    TextEditingController _tempNewSourceController = TextEditingController();
    String? newSourceName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neue Bezugsquelle hinzufügen'),
          content: TextField(
            controller: _tempNewSourceController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name der Bezugsquelle',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hinzufügen'),
              onPressed: () {
                if (_tempNewSourceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bezugsquellenname darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  // Do not pop, let user correct
                  return;
                }
                if (_currentSources.contains(
                  _tempNewSourceController.text.trim(),
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bezugsquelle "${_tempNewSourceController.text.trim()}" existiert bereits.',
                      ),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  // Do not pop, let user correct
                  return;
                }
                Navigator.of(context).pop(_tempNewSourceController.text.trim());
              },
            ),
          ],
        );
      },
    );

    if (newSourceName != null && newSourceName.isNotEmpty) {
      // Call the parent's callback to add the new source to HomeScreen's _allSources
      widget.onNewSourceCreated(newSourceName);
      setState(() {
        _currentSources.add(newSourceName); // Update internal list immediately
        // Ensure uniqueness and sort after adding
        Set<String> tempSources = Set<String>.from(_currentSources);
        _currentSources = tempSources.toList();
        _currentSources.sort();

        _selectedSource = newSourceName; // Select the newly added source
      });
      return newSourceName; // Return the new source name
    }
    return null; // No new source added or cancelled
  }

  @override
  Widget build(BuildContext context) {
    // Ensure 'Ohne' is always an option in the bottom sheet, if not already present
    List<String> displaySources = List.from(_currentSources);
    if (!displaySources.contains('Ohne')) {
      displaySources.insert(0, 'Ohne');
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bezugsquelle wählen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ), // Schriftgröße reduziert
          ),
          const SizedBox(height: 8), // Höhe reduziert
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  displaySources.length +
                  1, // +1 for "Neue Bezugsquelle hinzufügen..."
              itemBuilder: (context, index) {
                if (index < displaySources.length) {
                  final source = displaySources[index];
                  return ListTile(
                    dense: true, // Macht das ListTile kompakter
                    visualDensity:
                        VisualDensity.compact, // Macht das ListTile kompakter
                    title: Text(
                      source,
                      style: const TextStyle(fontSize: 11),
                    ), // Schriftgröße auf 75% reduziert
                    trailing: (_selectedSource ?? '') == source
                        ? const Icon(Icons.check, color: Colors.cyan, size: 15)
                        : null, // Added ?? ''
                    onTap: () {
                      widget.onSourceSelected(
                        source,
                      ); // Inform parent about selection
                    },
                  );
                } else {
                  // "Neue Bezugsquelle hinzufügen..." option
                  return ListTile(
                    dense: true, // Macht das ListTile kompakter
                    visualDensity:
                        VisualDensity.compact, // Macht das ListTile kompakter
                    leading: const Icon(
                      Icons.add,
                      size: 15,
                    ), // Größe auf 75% reduziert
                    title: const Text(
                      'Neue Bezugsquelle hinzufügen...',
                      style: TextStyle(fontSize: 11),
                    ), // Schriftgröße auf 75% reduziert
                    onTap: () async {
                      final String? newlyAddedSource =
                          await _showAddSourceDialogForBottomSheet();
                      if (newlyAddedSource != null) {
                        // If a new source was added, it's already selected in _selectedSource
                        // and added to _currentSources. Now, we need to inform the parent
                        // and close the bottom sheet.
                        widget.onSourceSelected(newlyAddedSource);
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// New Screen zur Verwaltung der Kategorien
class CategoryManagementScreen extends StatefulWidget {
  final List<String> availableCategories;
  final Function(String categoryName, {Color? categoryColor})
  onNewCategoryCreated;
  final Function(String categoryName) onCategoryDeleted;
  final Function(String oldName, String newName, Color? newColor)
  onCategoryRenamed;

  const CategoryManagementScreen({
    super.key,
    required this.availableCategories,
    required this.onNewCategoryCreated,
    required this.onCategoryDeleted,
    required this.onCategoryRenamed,
  });

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();
  List<String> _currentCategories = []; // Internal list for immediate display
  Color? _selectedNewCategoryColor; // For adding new category
  Color? _selectedEditCategoryColor; // For editing existing category

  // System-defined categories that cannot be deleted or renamed
  final List<String> _systemCategories = ['Alle', 'Ohne', 'Uncategorized'];

  @override
  void initState() {
    super.initState();
    // Filter out system categories like 'Alle', 'Ohne', 'Uncategorized'
    Set<String> uniqueCategories = Set<String>.from(
      widget.availableCategories.where(
        (cat) => !_systemCategories.contains(cat),
      ),
    );
    _currentCategories = uniqueCategories.toList();
    _currentCategories.sort(); // Sort for better display
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _editCategoryController.dispose();
    super.dispose();
  }

  // Dialog zum Hinzufügen einer neuen Kategorie
  Future<String?> _showAddCategoryDialog() async {
    // Changed return type to Future<String?>
    _newCategoryController.clear();
    _selectedNewCategoryColor = null; // Reset color selection
    final String? result = await showDialog<String>(
      // Await result from dialog
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neue Kategorie hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newCategoryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Name der neuen Kategorie',
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategoriename darf nicht leer sein.'),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                      Navigator.of(
                        context,
                      ).pop(null); // Return null on empty input
                      return;
                    }
                    final String newCategoryName = value.trim();
                    if (_categoryColors.containsKey(newCategoryName)) {
                      // Check against global _categoryColors
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kategorie "$newCategoryName" existiert bereits.',
                          ),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                      Navigator.of(
                        context,
                      ).pop(null); // Return null on error/duplicate
                      return;
                    }
                    widget.onNewCategoryCreated(
                      newCategoryName,
                      categoryColor: _selectedNewCategoryColor,
                    );
                    setState(() {
                      _currentCategories.add(newCategoryName);
                      _currentCategories.sort();
                    });
                    Navigator.of(
                      context,
                    ).pop(newCategoryName); // Return the new category name
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Wähle eine Farbe (optional):',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _predefinedPaletteColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNewCategoryColor = color;
                        });
                      },
                      child: Container(
                        width: 27, // Größe auf 75% reduziert
                        height: 27, // Größe auf 75% reduziert
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedNewCategoryColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2, // Breite auf 75% reduziert
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null on cancel
              },
            ),
            TextButton(
              child: const Text('Hinzufügen'),
              onPressed: () {
                if (_newCategoryController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategoriename darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                final String newCategoryName = _newCategoryController.text
                    .trim();
                if (_categoryColors.containsKey(newCategoryName)) {
                  // Check against global _categoryColors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Kategorie "$newCategoryName" existiert bereits.',
                      ),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                widget.onNewCategoryCreated(
                  newCategoryName,
                  categoryColor: _selectedNewCategoryColor,
                );
                setState(() {
                  _currentCategories.add(newCategoryName);
                  _currentCategories.sort();
                });
                Navigator.of(
                  context,
                ).pop(newCategoryName); // Return the new category name
              },
            ),
          ],
        );
      },
    );
    return result; // Return the result from the dialog
  }

  // Dialog zum Bearbeiten einer Kategorie
  Future<void> _showEditCategoryDialog(
    String oldCategoryName,
    int index,
  ) async {
    // Prevent editing system categories
    if (_systemCategories.contains(oldCategoryName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Systemkategorie "$oldCategoryName" kann nicht bearbeitet werden.',
          ),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    _editCategoryController.text = oldCategoryName;
    _selectedEditCategoryColor =
        _categoryColors[oldCategoryName]; // Pre-select current color

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kategorie bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editCategoryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Neuer Kategoriename',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Wähle eine neue Farbe (optional):',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _predefinedPaletteColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEditCategoryColor = color;
                        });
                      },
                      child: Container(
                        width: 27, // Größe auf 75% reduziert
                        height: 27, // Größe auf 75% reduziert
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedEditCategoryColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2, // Breite auf 75% reduziert
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Speichern'),
              onPressed: () {
                final String newCategoryName = _editCategoryController.text
                    .trim();
                if (newCategoryName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategoriename darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                  return;
                }
                if (newCategoryName != oldCategoryName &&
                    _categoryColors.containsKey(newCategoryName)) {
                  // Check against global _categoryColors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Kategorie "$newCategoryName" existiert bereits.',
                      ),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else {
                  widget.onCategoryRenamed(
                    oldCategoryName,
                    newCategoryName,
                    _selectedEditCategoryColor,
                  );
                  setState(() {
                    _currentCategories[index] = newCategoryName;
                    _currentCategories.sort();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Kategorien verwalten'),
        leading: IconButton(
          // Added leading back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              null,
            ); // Return null when simply navigating back
          },
        ),
      ),
      body: _currentCategories.isEmpty
          ? const Center(
              child: Text(
                'Noch keine Kategorien vorhanden. Füge neue hinzu!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _currentCategories.length,
              itemBuilder: (context, index) {
                final category = _currentCategories[index];
                // Do not allow system categories to be dismissed
                final bool isSystemCategory = _systemCategories.contains(
                  category,
                );

                return Dismissible(
                  key: Key(category),
                  direction: isSystemCategory
                      ? DismissDirection.none
                      : DismissDirection
                            .endToStart, // Prevent swipe for system categories
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 22.5,
                    ), // Größe auf 75% reduziert
                  ),
                  confirmDismiss: (direction) async {
                    if (isSystemCategory) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Systemkategorie "$category" kann nicht gelöscht werden.',
                          ),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                      return false; // Prevent dismissal
                    }
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Kategorie löschen?'),
                          content: Text(
                            'Möchtest du die Kategorie "$category" wirklich löschen? Alle Artikel dieser Kategorie werden der Kategorie "Ohne" zugewiesen.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    return confirm ?? false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      widget.onCategoryDeleted(category);
                      setState(() {
                        _currentCategories.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 500),
                          content: Text('Kategorie "$category" gelöscht.'),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2.0,
                    ), // Consistent margin
                    elevation: 1, // Consistent elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: _categoryColors[category] ?? Colors.grey,
                        width: 1.5,
                      ), // Add border with category color
                    ),
                    child: InkWell(
                      // Use InkWell for tap feedback
                      onTap: () {
                        _showEditCategoryDialog(category, index);
                      },
                      child: Padding(
                        // Add Padding for consistent internal spacing
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0.5,
                        ), // Consistent vertical padding
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 15.4,
                                ), // Font not bold
                              ),
                            ),
                            // Removed trailing color container
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed: () async {
                // Await the result
                final String? newCategory = await _showAddCategoryDialog();
                // If a new category was added, pop this screen and return its name
                if (newCategory != null) {
                  Navigator.pop(context, newCategory);
                }
              },
              tooltip: 'Neue Kategorie hinzufügen',
            ),
          ],
        ),
      ),
    );
  }
}

// New Screen for Article Management
class ArticleManagementScreen extends StatefulWidget {
  final Function(String categoryName, {Color? categoryColor})
  onNewCategoryCreated;
  final Function(String categoryName) onCategoryDeleted;
  final Function(String oldName, String newName, Color? newColor)
  onCategoryRenamed;
  final List<String> availableSources;
  final Function(String sourceName) onNewSourceCreated;
  final Function(String sourceName) onSourceDeleted;
  final Function(String oldName, String newName) onSourceRenamed;
  final VoidCallback onCategorizedItemsUpdated;
  final bool
  fromSelectionScreen; // New: Flag to indicate if navigated from SelectionScreen

  const ArticleManagementScreen({
    super.key,
    required this.onNewCategoryCreated,
    required this.onCategoryDeleted,
    required this.onCategoryRenamed,
    required this.availableSources,
    required this.onNewSourceCreated,
    required this.onSourceDeleted,
    required this.onSourceRenamed,
    required this.onCategorizedItemsUpdated,
    this.fromSelectionScreen = false, // Default to false
  });

  @override
  State<ArticleManagementScreen> createState() =>
      _ArticleManagementScreenState();
}

class _ArticleManagementScreenState extends State<ArticleManagementScreen> {
  final TextEditingController _articleNameController = TextEditingController();
  late String _selectedCategoryForDialog;
  late String _selectedSourceForDialog;
  List<String> _localAvailableSourcesForDialog = [];

  // System-defined categories that cannot be deleted or renamed from the master list
  final List<String> _systemCategories = ['Alle', 'Ohne', 'Uncategorized'];

  @override
  void initState() {
    super.initState();
    _selectedCategoryForDialog = 'Ohne';
    _selectedSourceForDialog = 'Ohne';
    _localAvailableSourcesForDialog = ['Ohne'];
    _loadLocalSourcesForDialog(); // Initial load for the dialog's source dropdown
  }

  @override
  void dispose() {
    _articleNameController.dispose();
    super.dispose();
  }

  // Loads sources specifically for the dialog's dropdown
  Future<void> _loadLocalSourcesForDialog() async {
    // This should reflect the current global _allSources from HomeScreen
    setState(() {
      Set<String> tempSources = Set<String>.from(widget.availableSources);
      if (!tempSources.contains('Ohne')) {
        tempSources.add('Ohne');
      }
      _localAvailableSourcesForDialog = tempSources.toList();
      _localAvailableSourcesForDialog.sort();
    });
  }

  // Helper function to check for duplicate article names across all categories in the master list
  bool _isArticleNameDuplicateInMasterList(String name) {
    for (var categoryItems in _categorizedItems.values) {
      if (categoryItems.any(
        (item) => item['name'].toString().toLowerCase() == name.toLowerCase(),
      )) {
        return true;
      }
    }
    return false;
  }

  // Dialog to add a new article to the master list
  Future<void> _showAddArticleDialog() async {
    _articleNameController.clear();
    _selectedCategoryForDialog =
        'Ohne'; // Reset to default category for new article
    _selectedSourceForDialog =
        'Ohne'; // Reset to default source for new article
    await _loadLocalSourcesForDialog(); // Ensure sources are up-to-date before opening dialog

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog state
          builder: (BuildContext context, StateSetter setState) {
            List<String> dropdownCategories = List.from(
              _categoryColors.keys.toList(),
            );
            if (dropdownCategories.contains('Ohne')) {
              dropdownCategories.remove('Ohne');
              dropdownCategories.insert(0, 'Ohne');
            }
            dropdownCategories.remove('Alle');
            dropdownCategories.remove('Uncategorized');
            dropdownCategories.add('__MANAGE_CATEGORIES__');

            List<String> dropdownSources = List.from(
              _localAvailableSourcesForDialog,
            );
            dropdownSources.add('__MANAGE_SOURCES__');

            return AlertDialog(
              title: const Text('Neuen Artikel hinzufügen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _articleNameController,
                      decoration: InputDecoration(
                        labelText: 'Artikelname',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryForDialog,
                      decoration: InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: dropdownCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category == '__MANAGE_CATEGORIES__'
                                ? 'Neue Kategorie anlegen...'
                                : category,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue == '__MANAGE_CATEGORIES__') {
                          final String? newCategoryName = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryManagementScreen(
                                availableCategories: _categoryColors.keys
                                    .toList(),
                                onNewCategoryCreated:
                                    widget.onNewCategoryCreated,
                                onCategoryDeleted: widget.onCategoryDeleted,
                                onCategoryRenamed: widget.onCategoryRenamed,
                              ),
                            ),
                          );
                          if (newCategoryName != null) {
                            setState(() {
                              // Update dialog state
                              _selectedCategoryForDialog = newCategoryName;
                            });
                          }
                          // The parent HomeScreen's _addNewCategory already calls _saveData, so _categoryColors is updated.
                          // No explicit rebuild of dropdownCategories needed here as StatefulBuilder handles it.
                        } else {
                          setState(() {
                            // Update dialog state
                            _selectedCategoryForDialog = newValue!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedSourceForDialog,
                      decoration: InputDecoration(
                        labelText: 'Bezugsquelle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: dropdownSources.map((String source) {
                        return DropdownMenuItem<String>(
                          value: source,
                          child: Text(
                            source == '__MANAGE_SOURCES__'
                                ? 'Neue Bezugsquelle hinzufügen...'
                                : source,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue == '__MANAGE_SOURCES__') {
                          final String? newSourceName = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SourceManagementScreen(
                                availableSources: widget.availableSources,
                                onNewSourceCreated: widget.onNewSourceCreated,
                                onSourceDeleted: widget.onSourceDeleted,
                                onSourceRenamed: widget.onSourceRenamed,
                              ),
                            ),
                          );
                          if (newSourceName != null) {
                            await _loadLocalSourcesForDialog(); // Reload sources for dialog
                            setState(() {
                              // Update dialog state
                              _selectedSourceForDialog = newSourceName;
                            });
                          }
                        } else {
                          setState(() {
                            // Update dialog state
                            _selectedSourceForDialog = newValue!;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Speichern'),
                  onPressed: () {
                    String articleName = _articleNameController.text.trim();
                    if (articleName.isEmpty ||
                        _selectedCategoryForDialog.isEmpty ||
                        _selectedSourceForDialog.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bitte gib einen Artikelnamen, wähle eine Kategorie und Bezugsquelle.',
                          ),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                      return;
                    }
                    if (_isArticleNameDuplicateInMasterList(articleName)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Artikel "$articleName" existiert bereits in der Masterliste. Bitte wähle einen anderen Namen.',
                          ),
                          duration: Duration(milliseconds: 2000),
                        ),
                      );
                      return;
                    }

                    // Add to global _categorizedItems
                    if (!_categorizedItems.containsKey(
                      _selectedCategoryForDialog,
                    )) {
                      _categorizedItems[_selectedCategoryForDialog] = [];
                    }
                    _categorizedItems[_selectedCategoryForDialog]!.add({
                      'name': articleName,
                      'category': _selectedCategoryForDialog,
                      'isDone': false, // Always false for master list items
                      'source': _selectedSourceForDialog,
                    });
                    widget
                        .onCategorizedItemsUpdated(); // Notify HomeScreen to save

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Artikel "$articleName" zur Masterliste hinzugefügt.',
                        ),
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                    Navigator.of(
                      dialogContext,
                    ).pop(); // Close the add article dialog

                    // If navigated from SelectionScreen, pop ArticleManagementScreen
                    if (widget.fromSelectionScreen) {
                      Navigator.of(
                        context,
                      ).pop(); // Pop ArticleManagementScreen
                    } else {
                      // Otherwise, just refresh the current ArticleManagementScreen
                      this.setState(
                        () {},
                      ); // This setState is for the _ArticleManagementScreenState
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to edit an existing article in the master list
  Future<void> _showEditArticleDialog(
    Map<String, dynamic> articleToEdit,
  ) async {
    _articleNameController.text = articleToEdit['name']!;
    _selectedCategoryForDialog = articleToEdit['category']!;
    _selectedSourceForDialog = articleToEdit['source']!;
    await _loadLocalSourcesForDialog(); // Ensure sources are up-to-date before opening dialog

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<String> dropdownCategories = List.from(
              _categoryColors.keys.toList(),
            );
            if (dropdownCategories.contains('Ohne')) {
              dropdownCategories.remove('Ohne');
              dropdownCategories.insert(0, 'Ohne');
            }
            dropdownCategories.remove('Alle');
            dropdownCategories.remove('Uncategorized');
            dropdownCategories.add('__MANAGE_CATEGORIES__');

            List<String> dropdownSources = List.from(
              _localAvailableSourcesForDialog,
            );
            dropdownSources.add('__MANAGE_SOURCES__');

            return AlertDialog(
              title: const Text('Artikel bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _articleNameController,
                      decoration: InputDecoration(
                        labelText: 'Artikelname',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryForDialog,
                      decoration: InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: dropdownCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category == '__MANAGE_CATEGORIES__'
                                ? 'Neue Kategorie anlegen...'
                                : category,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue == '__MANAGE_CATEGORIES__') {
                          final String? newCategoryName = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryManagementScreen(
                                availableCategories: _categoryColors.keys
                                    .toList(),
                                onNewCategoryCreated:
                                    widget.onNewCategoryCreated,
                                onCategoryDeleted: widget.onCategoryDeleted,
                                onCategoryRenamed: widget.onCategoryRenamed,
                              ),
                            ),
                          );
                          if (newCategoryName != null) {
                            setState(() {
                              _selectedCategoryForDialog = newCategoryName;
                            });
                          }
                        } else {
                          setState(() {
                            _selectedCategoryForDialog = newValue!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedSourceForDialog,
                      decoration: InputDecoration(
                        labelText: 'Bezugsquelle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: dropdownSources.map((String source) {
                        return DropdownMenuItem<String>(
                          value: source,
                          child: Text(
                            source == '__MANAGE_SOURCES__'
                                ? 'Neue Bezugsquelle hinzufügen...'
                                : source,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue == '__MANAGE_SOURCES__') {
                          final String? newSourceName = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SourceManagementScreen(
                                availableSources: widget.availableSources,
                                onNewSourceCreated: widget.onNewSourceCreated,
                                onSourceDeleted: widget.onSourceDeleted,
                                onSourceRenamed: widget.onSourceRenamed,
                              ),
                            ),
                          );
                          if (newSourceName != null) {
                            await _loadLocalSourcesForDialog();
                            setState(() {
                              _selectedSourceForDialog = newSourceName;
                            });
                          }
                        } else {
                          setState(() {
                            _selectedSourceForDialog = newValue!;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Speichern'),
                  onPressed: () {
                    String newArticleName = _articleNameController.text.trim();
                    if (newArticleName.isEmpty ||
                        _selectedCategoryForDialog.isEmpty ||
                        _selectedSourceForDialog.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bitte gib einen Artikelnamen, wähle eine Kategorie und Bezugsquelle.',
                          ),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                      return;
                    }
                    // Check for duplicate name, excluding the current article being edited
                    bool isDuplicate = false;
                    _categorizedItems.forEach((category, items) {
                      if (items.any(
                        (item) =>
                            item['name'].toString().toLowerCase() ==
                                newArticleName.toLowerCase() &&
                            item != articleToEdit,
                      )) {
                        // Exclude the article being edited
                        isDuplicate = true;
                      }
                    });

                    if (isDuplicate) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Artikel "$newArticleName" existiert bereits in der Masterliste. Bitte wähle einen anderen Namen.',
                          ),
                          duration: Duration(milliseconds: 2000),
                        ),
                      );
                      return;
                    }

                    // Remove old article if category or name changed
                    if (articleToEdit['name'] != newArticleName ||
                        articleToEdit['category'] !=
                            _selectedCategoryForDialog) {
                      _categorizedItems[articleToEdit['category']]?.removeWhere(
                        (item) => item == articleToEdit,
                      );
                      if (_categorizedItems[articleToEdit['category']]
                              ?.isEmpty ??
                          false) {
                        _categorizedItems.remove(articleToEdit['category']);
                      }
                    }

                    // Update article details
                    articleToEdit['name'] = newArticleName;
                    articleToEdit['category'] = _selectedCategoryForDialog;
                    articleToEdit['source'] = _selectedSourceForDialog;

                    // Add to new category if category changed
                    if (!_categorizedItems.containsKey(
                      _selectedCategoryForDialog,
                    )) {
                      _categorizedItems[_selectedCategoryForDialog] = [];
                    }
                    // Only add if it's not already in the list (e.g., if only source changed)
                    if (!_categorizedItems[_selectedCategoryForDialog]!
                        .contains(articleToEdit)) {
                      _categorizedItems[_selectedCategoryForDialog]!.add(
                        articleToEdit,
                      );
                    }

                    widget
                        .onCategorizedItemsUpdated(); // Notify HomeScreen to save

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Artikel "$newArticleName" aktualisiert.',
                        ),
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                    Navigator.of(
                      dialogContext,
                    ).pop(); // Close the edit article dialog
                    this.setState(() {}); // Refresh the ArticleManagementScreen
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group and sort articles for display
    Map<String, List<Map<String, dynamic>>> groupedArticles = {};
    _categorizedItems.forEach((category, items) {
      if (!_systemCategories.contains(category)) {
        // Exclude system categories from direct display
        groupedArticles[category] = List.from(items);
        groupedArticles[category]!.sort(
          (a, b) => a['name'].compareTo(b['name']),
        );
      }
    });

    List<String> sortedCategories = groupedArticles.keys.toList();
    sortedCategories.sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Artikel verwalten'),
        leading: IconButton(
          // Added leading back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Simply pop the screen
          },
        ),
      ),
      body: sortedCategories.isEmpty
          ? const Center(
              child: Text(
                'Noch keine Artikel in der Masterliste vorhanden. Füge neue hinzu!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedCategories.length,
              itemBuilder: (context, categoryIndex) {
                final categoryName = sortedCategories[categoryIndex];
                final articles = groupedArticles[categoryName]!;
                final categoryColor =
                    _categoryColors[categoryName] ?? Colors.grey;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        4,
                      ), // Padding zurückgesetzt
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize:
                              14.4, // Font-Größe der Kategorienüberschrift auf 80% (18 * 0.8)
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    ...articles.map((article) {
                      return Dismissible(
                        key: Key(
                          article['name']! + article['category']!,
                        ), // Unique key for Dismissible
                        direction:
                            DismissDirection.endToStart, // Swipe to delete
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 22.5,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Artikel löschen?'),
                                  content: Text(
                                    'Möchtest du den Artikel "${article['name']}" wirklich löschen?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Abbrechen'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Löschen',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                            return confirm ?? false;
                          }
                          return false; // Should not happen for other directions
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            setState(() {
                              _categorizedItems[categoryName]?.removeWhere(
                                (item) => item == article,
                              );
                              // Remove category if it becomes empty after deletion
                              if (_categorizedItems[categoryName]?.isEmpty ??
                                  false) {
                                _categorizedItems.remove(categoryName);
                                sortedCategories.remove(
                                  categoryName,
                                ); // Update sorted categories list
                              }
                              widget
                                  .onCategorizedItemsUpdated(); // Save changes
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 500),
                                content: Text(
                                  'Artikel "${article['name']}" gelöscht.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2.0,
                          ), // Vertical margin set to 2.0
                          elevation: 1, // Elevation reduziert
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(
                              color: categoryColor,
                              width: 1.5,
                            ), // Rahmenbreite reduziert
                          ),
                          child: InkWell(
                            // Add InkWell to make the card tappable
                            onTap: () {
                              _showEditArticleDialog(
                                article,
                              ); // Call edit dialog on tap
                            },
                            child: Padding(
                              // Add Padding around the custom content
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0.5,
                              ), // Vertical padding halbiert
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize
                                          .min, // Make column take minimum vertical space
                                      children: [
                                        Text(
                                          article['name']!,
                                          style: const TextStyle(
                                            fontSize: 15.4,
                                            fontWeight: FontWeight.bold,
                                          ), // Schriftgröße auf 10% größer (14 * 1.1)
                                        ),
                                        Text(
                                          'Bezugsquelle: ${article['source'] ?? 'Ohne'}',
                                          style: const TextStyle(
                                            fontSize: 10.8,
                                            color: Colors.grey,
                                          ), // Schriftgröße auf 20% größer (9 * 1.2)
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit icon (rechtsbündig) - REMOVED, functionality moved to onTap
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 21,
              ), // Größe auf 75% reduziert
              onPressed: _showAddArticleDialog,
              tooltip: 'Neuen Artikel zur Masterliste hinzufügen',
            ),
          ],
        ),
      ),
    );
  }
}

// Neuer Platzhalter-Screen zur Verwaltung der Einkaufslisten
class ListManagementScreen extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> allShoppingLists;
  final String currentListName;
  final Function(String oldName, String newName) onRenameList;
  final Function(String listName) onDeleteList;
  final Function(String listName) onCreateNewList;
  final VoidCallback onSaveData;
  final Function(String listName)
  onListSelected; // Callback to update currentListName in HomeScreen

  const ListManagementScreen({
    super.key,
    required this.allShoppingLists,
    required this.currentListName,
    required this.onRenameList,
    required this.onDeleteList,
    required this.onCreateNewList,
    required this.onSaveData,
    required this.onListSelected,
  });

  @override
  State<ListManagementScreen> createState() => _ListManagementScreenState();
}

class _ListManagementScreenState extends State<ListManagementScreen> {
  late String
  _tempCurrentListName; // New local state for immediate checkbox update

  @override
  void initState() {
    super.initState();
    _tempCurrentListName =
        widget.currentListName; // Initialize with parent's current list
  }

  // Dialog zum Umbenennen einer Einkaufsliste
  Future<void> _showRenameListDialog(String oldListName) async {
    TextEditingController _renameController = TextEditingController(
      text: oldListName,
    );
    String? newListName;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Liste umbenennen'),
          content: TextField(
            controller: _renameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Neuer Listenname'),
            onChanged: (value) {
              newListName = value;
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onRenameList(oldListName, value.trim());
                Navigator.of(context).pop();
                setState(() {}); // Trigger rebuild of ListManagementScreen
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Umbenennen'),
              onPressed: () {
                final String nameToUse =
                    newListName?.trim() ?? _renameController.text.trim();
                if (nameToUse.isNotEmpty) {
                  widget.onRenameList(oldListName, nameToUse);
                  Navigator.of(context).pop();
                  setState(() {}); // Trigger rebuild of ListManagementScreen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 1000),
                      content: Text('Listenname darf nicht leer sein.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog zum Erstellen einer neuen Einkaufsliste
  Future<void> _showCreateNewListDialog() async {
    TextEditingController _listNameController = TextEditingController();
    String? newListName;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neue Einkaufsliste'),
          content: TextField(
            controller: _listNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Listenname'),
            onChanged: (value) {
              newListName = value;
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onCreateNewList(value.trim());
                Navigator.of(context).pop();
                setState(() {}); // Trigger rebuild of ListManagementScreen
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Erstellen'),
              onPressed: () {
                if (newListName != null && newListName!.trim().isNotEmpty) {
                  widget.onCreateNewList(newListName!.trim());
                  Navigator.of(context).pop();
                  setState(() {}); // Trigger rebuild of ListManagementScreen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listenname darf nicht leer sein.'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort the list names alphabetically
    List<String> sortedListNames = widget.allShoppingLists.keys.toList();
    sortedListNames.sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Listen verwalten'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: sortedListNames.isEmpty
          ? const Center(
              child: Text(
                'Noch keine Listen vorhanden. Erstelle eine neue Liste!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedListNames.length,
              itemBuilder: (context, index) {
                final listName = sortedListNames[index];
                final bool isCurrent =
                    _tempCurrentListName ==
                    listName; // Use local state for checkbox value

                return Dismissible(
                  key: Key(listName), // Unique key for Dismissible
                  direction: DismissDirection
                      .endToStart, // Swipe from right to left to delete
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 22.5,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (widget.allShoppingLists.length == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(milliseconds: 1500),
                          content: Text(
                            'Die letzte Liste kann nicht gelöscht werden.',
                          ),
                        ),
                      );
                      return false; // Prevent dismissal
                    }
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Liste löschen?'),
                          content: Text(
                            'Möchtest du die Liste "$listName" wirklich löschen?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    return confirm ?? false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      widget.onDeleteList(listName);
                      setState(() {}); // Trigger rebuild to reflect deletion
                    }
                  },
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      listName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    // No 'selected' property here, as selection is now via checkbox
                    onTap: () {
                      // Tapping the title now triggers rename
                      _showRenameListDialog(listName);
                    },
                    trailing: Transform.scale(
                      scale: 0.8, // Make checkbox slightly smaller
                      child: Checkbox(
                        value: isCurrent,
                        activeColor: Colors.red, // Use red for active checkbox
                        checkColor: Colors.white,
                        onChanged: (bool? newValue) {
                          if (newValue == true && !isCurrent) {
                            setState(() {
                              _tempCurrentListName =
                                  listName; // Update local state immediately
                            });
                            // Inform parent and then pop after a small delay
                            widget.onListSelected(listName);
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                Navigator.pop(context);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 21),
              onPressed: () async {
                await _showCreateNewListDialog();
                // After dialog closes, the list in HomeScreen is updated via callback.
                // We need to trigger a rebuild of this screen to reflect the changes.
                setState(() {});
              },
              tooltip: 'Neue Liste erstellen',
            ),
          ],
        ),
      ),
    );
  }
}
