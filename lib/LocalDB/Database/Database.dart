import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:j_food_updated/LocalDB/Models/CategoryItem.dart';
import 'package:j_food_updated/LocalDB/Models/PackageCartItem.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../Models/CartItem.dart';
import '../Models/FavoriteItem.dart';

class CartDatabaseHelper {
  static final CartDatabaseHelper _instance = CartDatabaseHelper._internal();
  static final int dbVersion = 32; // Increment for cart working hours

  factory CartDatabaseHelper() => _instance;

  CartDatabaseHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  Future<CartItem?> getCartItemByProductId(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'cart',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return CartItem.fromJson(maps.first);
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'j_food_updated.db');

    return await openDatabase(
      path,
      version: dbVersion,
      onUpgrade: _onUpgrade,
      onCreate: (db, version) async {
        await _createDb(db);
      },
    );
  }

  Future<void> _createDb(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        image TEXT NOT NULL,
        price TEXT NOT NULL,
        size TEXT NOT NULL,
        sizeId TEXT NOT NULL,
        total TEXT NOT NULL,
        storeID TEXT NOT NULL,
        storeName TEXT NOT NULL,
        storeImage TEXT NOT NULL,
        storeLocation TEXT NOT NULL,
        storeDeliveryPrice TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        components_names TEXT NOT NULL,
        components_prices TEXT NOT NULL,
        selected_components_names TEXT NOT NULL,
        selected_components_prices TEXT NOT NULL,
        drinks_names TEXT NOT NULL,
        drinks_prices TEXT NOT NULL,
        selected_drinks_names TEXT NOT NULL,
        selected_drinks_prices TEXT NOT NULL,
        selected_components_id TEXT,
        selected_components_images TEXT,
        components_images TEXT,
        drinks_images TEXT,
        selected_drinks_images TEXT,
        selected_drinks_id TEXT, 
        selected_components_qty TEXT,
        selected_drinks_qty TEXT,
        storeOpenTime TEXT,
        storeCloseTime TEXT,
        workingHours TEXT NOT NULL DEFAULT '[]',
        isOpen INTEGER NOT NULL DEFAULT 0,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS package_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageId INTEGER NOT NULL,
        packageName TEXT NOT NULL,
        packageImage TEXT NOT NULL,
        packagePrice TEXT NOT NULL,
        total TEXT NOT NULL,
        storeID TEXT NOT NULL,
        storeName TEXT NOT NULL,
        storeImage TEXT NOT NULL,
        storeLocation TEXT NOT NULL,
        storeDeliveryPrice TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        productNames TEXT NOT NULL, 
        productIds TEXT NOT NULL, 
        productComponents TEXT NOT NULL, 
        selected_drinks_id TEXT NOT NULL,
        selected_drinks_names TEXT NOT NULL,
        selected_drinks_prices TEXT NOT NULL,
        selected_drinks_qty TEXT NOT NULL,
        storeOpenTime TEXT,
        storeCloseTime TEXT,
        workingHours TEXT NOT NULL DEFAULT '[]',
        isOpen INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_favouites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storeId INTEGER NOT NULL,
        categoryID INTEGER NOT NULL,
        storeName TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        storeImage TEXT NOT NULL,
        storeLocation TEXT NOT NULL,
        openTime TEXT NOT NULL,    
        closeTime TEXT NOT NULL,
        workingHours TEXT NOT NULL DEFAULT '[]',
        isOpen INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop existing tables
    await db.execute('DROP TABLE IF EXISTS cart');
    await db.execute('DROP TABLE IF EXISTS package_cart');
    await db.execute('DROP TABLE IF EXISTS store_favouites');
    await db.execute('DROP TABLE IF EXISTS categories');
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    // Recreate tables with updated schema
    await _createDb(db);
  }

  Future<FavoriteItem?> getFavoriteItemByProductId(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'store_favouites',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return FavoriteItem.fromJson(maps.first);
  }

  Future<int> insertFavoriteItem(FavoriteItem item) async {
    final db = await database;
    return await db!.insert('store_favouites', item.toJson());
  }

  Future<List<FavoriteItem>> getFavoriteItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('store_favouites');
    return List.generate(
      maps.length,
      (i) => FavoriteItem.fromJson(maps[i]),
    );
  }

  Future<void> deleteFavoriteItem(int id) async {
    final db = await database;
    await db!.delete('store_favouites', where: 'storeId = ?', whereArgs: [id]);
  }

  // Method to clear the cart database
  Future<void> clearCart() async {
    final db = await database;
    await db!.delete('cart'); // Delete all records from the 'cart' table
  }

  Future<int> insertCartItem(CartItem item) async {
    final db = await database;
    return await db!.insert('cart', {
      'productId': item.productId,
      'name': item.name,
      'total': item.total,
      'price': item.price,
      'size': item.size,
      'sizeId': item.sizeId,
      'image': item.image,
      'storeID': item.storeID,
      'storeName': item.storeName,
      'storeImage': item.storeImage,
      'storeLocation': item.storeLocation,
      'storeDeliveryPrice': item.storeDeliveryPrice,
      'quantity': item.quantity,
      'components_names': item.components_names.join(','),
      'components_prices': item.components_prices.join(','),
      'selected_components_names': item.selected_components_names.join(','),
      'selected_components_prices': item.selected_components_prices.join(','),
      'drinks_names': item.drinks_names.join(','),
      'drinks_prices': item.drinks_prices.join(','),
      'selected_drinks_names': item.selected_drinks_names.join(','),
      'selected_drinks_images': item.selected_drinks_images.join(','),
      'selected_components_images': item.selected_components_images.join(','),
      'drinks_images': item.drinks_images.join(','),
      'components_images': item.components_images.join(','),
      'selected_drinks_prices': item.selected_drinks_prices.join(','),
      'selected_drinks_id': item.selected_drinks_id.join(','),
      'selected_components_id': item.selected_components_id.join(','),
      'selected_drinks_qty': item.selected_drinks_qty.join(','),
      'selected_components_qty': item.selected_components_qty.join(','),
      'storeOpenTime': item.storeOpenTime,
      'storeCloseTime': item.storeCloseTime,
      'note': item.note ?? '',
    });
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('cart');
    return List.generate(
      maps.length,
      (i) => CartItem.fromJson(maps[i]),
    );
  }

  Future<void> deleteCartItem(int id) async {
    final db = await database;
    await db!.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCartItem(CartItem item) async {
    final db = await database;
    await db!.update(
      'cart',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<CategoryItem>> getCategories() async {
    final db = await database;
    final result = await db!.query('categories');
    return result.map((json) => CategoryItem.fromJson(json)).toList();
  }

  Future<void> insertCategory(CategoryItem category) async {
    final db = await database;
    await db!.insert(
      'categories',
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db!.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<CategoryItem?> getCategoryById(int categoryId) async {
    final db = await database;
    final result =
        await db!.query('categories', where: 'id = ?', whereArgs: [categoryId]);
    if (result.isNotEmpty) {
      return CategoryItem.fromJson(result.first);
    }
    return null;
  }

  Future<void> deleteAllCategories() async {
    final db = await database;
    await db!.delete('categories');
  }

  Future<List<CategoryItem>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('categories');
    return List.generate(maps.length, (i) {
      return CategoryItem(
        id: maps[i]['id'],
        name: maps[i]['name'],
        image: maps[i]['image'],
      );
    });
  }

  Future<int> insertPackageCartItem(PackageCartItem item) async {
    final db = await database;

    return await db!.insert('package_cart', {
      'packageId': item.packageId,
      'packageName': item.packageName,
      'packageImage': item.packageImage,
      'packagePrice': item.packagePrice,
      'total': item.total,
      'storeID': item.storeID,
      'storeName': item.storeName,
      'storeImage': item.storeImage,
      'storeLocation': item.storeLocation,
      'storeDeliveryPrice': item.storeDeliveryPrice,
      'quantity': item.quantity,

      // Store productNames as a comma-separated string
      'productNames': item.productNames.join(','),
      'productIds': item.productIds.join(','),

      // Serialize productComponents as a JSON string
      'productComponents': jsonEncode(item.productComponents.map((key, value) {
        return MapEntry(key, value.toJson());
      })),

      // Store selectedDrinksNames, selectedDrinksPrices, selectedDrinksQty as comma-separated strings
      'selected_drinks_names': item.selected_drinks_names.join(','),
      'selected_drinks_prices': item.selected_drinks_prices.join(','),
      'selected_drinks_qty': item.selected_drinks_qty.join(','),
      'selected_drinks_id': item.selected_drinks_id.join(','),
      'storeOpenTime': item.storeOpenTime,
      'storeCloseTime': item.storeCloseTime,
    });
  }

  Future<PackageCartItem?> getPackageCartItemByPackageId(int packageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'package_cart',
      where: 'packageId = ?',
      whereArgs: [packageId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return PackageCartItem.fromJson(maps.first);
  }

  Future<List<PackageCartItem>> getPackageCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('package_cart');
    return List.generate(
      maps.length,
      (i) => PackageCartItem.fromJson(maps[i]),
    );
  }

  Future<void> deletePackageCartItem(int id) async {
    final db = await database;
    await db!.delete('package_cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePackageCartItem(PackageCartItem item) async {
    final db = await database;
    await db!.update(
      'package_cart',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> clearPackageCart() async {
    final db = await database;
    await db!.delete('package_cart');
  }
}
