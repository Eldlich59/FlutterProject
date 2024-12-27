import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clinic.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Bảng BENHNHAN
    await db.execute('''
      CREATE TABLE BENHNHAN (
        MaBN VARCHAR(20) PRIMARY KEY,
        TenBN VARCHAR(100) NOT NULL,
        NgaySinh DATE NOT NULL,
        GioiTinh VARCHAR(10) NOT NULL,
        DiaChi VARCHAR(200),
        SDT VARCHAR(15)
      )
    ''');

    // Bảng PHIEUKHAM
    await db.execute('''
      CREATE TABLE PHIEUKHAM (
        MaPK VARCHAR(20) PRIMARY KEY,
        NgayKham DATE NOT NULL,
        TrieuChung TEXT,
        ChuanDoan TEXT,
        TienKham REAL NOT NULL,
        MaBN VARCHAR(20) NOT NULL,
        FOREIGN KEY (MaBN) REFERENCES BENHNHAN (MaBN)
      )
    ''');

    // Bảng TOATHUOC
    await db.execute('''
      CREATE TABLE TOATHUOC (
        MaToa VARCHAR(20) PRIMARY KEY,
        Bsketoa VARCHAR(100) NOT NULL,
        Ngayketoa DATE NOT NULL,
        MaBN VARCHAR(20) NOT NULL,
        MaPK VARCHAR(20) NOT NULL,
        FOREIGN KEY (MaBN) REFERENCES BENHNHAN (MaBN),
        FOREIGN KEY (MaPK) REFERENCES PHIEUKHAM (MaPK)
      )
    ''');

    // Bảng THUOC
    await db.execute('''
      CREATE TABLE THUOC (
        MaThuoc VARCHAR(20) PRIMARY KEY,
        TenThuoc VARCHAR(100) NOT NULL,
        DonVi VARCHAR(20) NOT NULL,
        DonGia REAL NOT NULL,
        Ngaysx DATE NOT NULL,
        Hansudung DATE NOT NULL
      )
    ''');

    // Bảng CHITIETTOATHUOC
    await db.execute('''
      CREATE TABLE CHITIETTOATHUOC (
        MaToa VARCHAR(20) NOT NULL,
        MaThuoc VARCHAR(20) NOT NULL,
        Sluong INTEGER NOT NULL CHECK (Sluong > 0),
        Cdung TEXT,
        PRIMARY KEY (MaToa, MaThuoc),
        FOREIGN KEY (MaToa) REFERENCES TOATHUOC (MaToa),
        FOREIGN KEY (MaThuoc) REFERENCES THUOC (MaThuoc)
      )
    ''');

    // Bảng HOADONTHUOC
    await db.execute('''
      CREATE TABLE HOADONTHUOC (
        MaHD VARCHAR(20) PRIMARY KEY,
        Ngayban DATE NOT NULL,
        TienThuoc REAL NOT NULL CHECK (TienThuoc >= 0),
        MaToa VARCHAR(20) NOT NULL,
        FOREIGN KEY (MaToa) REFERENCES TOATHUOC (MaToa)
      )
    ''');
  }

  // Add these new methods
  Future<void> createPatient(Map<String, dynamic> patient) async {
    final db = await database;
    await db.insert(
      'BENHNHAN',
      patient,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return await db.query('BENHNHAN');
  }

  Future<void> insertDemoData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert demo patients
      await txn.rawInsert('''
        INSERT INTO BENHNHAN (MaBN, TenBN, NgaySinh, GioiTinh, DiaChi, SDT)
        VALUES 
          ('BN001', 'Nguyen Van A', '1990-01-15', 'Nam', 'Ha Noi', '0901234567'),
          ('BN002', 'Tran Thi B', '1985-05-20', 'Nu', 'Ho Chi Minh', '0912345678'),
          ('BN003', 'Le Van C', '1995-08-10', 'Nam', 'Da Nang', '0923456789')
      ''');

      // Insert demo medical examinations
      await txn.rawInsert('''
        INSERT INTO PHIEUKHAM (MaPK, NgayKham, TrieuChung, ChuanDoan, TienKham, MaBN)
        VALUES 
          ('PK001', '2023-11-01', 'Sot, dau dau', 'Cam cum', 100000, 'BN001'),
          ('PK002', '2023-11-02', 'Dau bung', 'Roi loan tieu hoa', 150000, 'BN002'),
          ('PK003', '2023-11-03', 'Ho khan', 'Viem hong', 120000, 'BN003')
      ''');

      // Insert demo medicines
      await txn.rawInsert('''
        INSERT INTO THUOC (MaThuoc, TenThuoc, DonVi, DonGia, Ngaysx, Hansudung)
        VALUES 
          ('T001', 'Paracetamol', 'Vien', 2000, '2023-01-01', '2025-01-01'),
          ('T002', 'Vitamin C', 'Vien', 1500, '2023-02-01', '2025-02-01'),
          ('T003', 'Amoxicillin', 'Vien', 5000, '2023-03-01', '2025-03-01')
      ''');

      // Insert demo prescriptions
      await txn.rawInsert('''
        INSERT INTO TOATHUOC (MaToa, Bsketoa, Ngayketoa, MaBN, MaPK)
        VALUES 
          ('TT001', 'Dr. Nguyen', '2023-11-01', 'BN001', 'PK001'),
          ('TT002', 'Dr. Tran', '2023-11-02', 'BN002', 'PK002'),
          ('TT003', 'Dr. Le', '2023-11-03', 'BN003', 'PK003')
      ''');

      // Insert demo prescription details
      await txn.rawInsert('''
        INSERT INTO CHITIETTOATHUOC (MaToa, MaThuoc, Sluong, Cdung)
        VALUES 
          ('TT001', 'T001', 10, 'Uong 1 vien/lan x 2 lan/ngay'),
          ('TT001', 'T002', 20, 'Uong 1 vien/ngay'),
          ('TT002', 'T003', 15, 'Uong 1 vien/lan x 3 lan/ngay')
      ''');

      // Insert demo medicine bills
      await txn.rawInsert('''
        INSERT INTO HOADONTHUOC (MaHD, Ngayban, TienThuoc, MaToa)
        VALUES 
          ('HD001', '2023-11-01', 40000, 'TT001'),
          ('HD002', '2023-11-02', 75000, 'TT002'),
          ('HD003', '2023-11-03', 30000, 'TT003')
      ''');
    });
  }
}
