import 'package:flutter/material.dart'; // Mengimpor pustaka dasar Flutter
import 'package:http/http.dart' as http; // Mengimpor pustaka HTTP client
import 'dart:convert'; // Mengimpor pustaka untuk mengelola data JSON
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor pustaka Flutter Bloc

// Model untuk merepresentasikan universitas
class University {
  String name;
  String website;

  University(
      {required this.name,
      required this.website}); // Constructor untuk mendefinisikan nama dan website universitas

  University.fromJson(
      Map<String, dynamic>
          json) // Constructor dari JSON untuk membuat objek University dari data JSON
      : name = json['name'],
        website = json['web_pages']
            [0]; // Mengambil nama dan website universitas dari JSON
}

// Model untuk menyimpan daftar universitas
class UniversitiesList {
  List<University> universities = []; // List untuk menyimpan objek University

  UniversitiesList.fromJson(List<dynamic> json) {
    // Constructor untuk membuat objek UniversitiesList dari data JSON
    universities = json.map((university) {
      // Mengonversi setiap item dalam JSON menjadi objek University dan menyimpannya dalam list
      return University.fromJson(university);
    }).toList();
  }
}

// Cubit untuk mengelola state negara ASEAN yang dipilih
class CountryCubit extends Cubit<String> {
  CountryCubit() : super("Indonesia"); // Menetapkan negara default

  void updateCountry(String country) =>
      emit(country); // Memperbarui negara yang dipilih
}

// Cubit untuk mengelola state daftar universitas berdasarkan negara yang dipilih
class UniversityCubit extends Cubit<UniversitiesList> {
  UniversityCubit()
      : super(UniversitiesList.fromJson(
            [])); // Menetapkan daftar universitas awal kosong

  void fetchUniversities(String country) async {
    // Mengambil daftar universitas dari API berdasarkan negara yang dipilih
    String url = "http://universities.hipolabs.com/search?country=$country";
    final response = await http.get(Uri.parse(
        url)); // Melakukan panggilan HTTP untuk mendapatkan data universitas

    if (response.statusCode == 200) {
      // Jika permintaan berhasil
      emit(UniversitiesList.fromJson(jsonDecode(response
          .body))); // Mengemis keadaan baru dengan daftar universitas yang diperbarui
    } else {
      throw Exception('Gagal load');
    }
  }
}

void main() {
  runApp(MyApp()); // Memulai aplikasi Flutter
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Menyediakan beberapa BlocProvider dalam satu widget tree
      providers: [
        BlocProvider<CountryCubit>(
            create: (_) =>
                CountryCubit()), // Menyediakan CountryCubit kepada widget tree
        BlocProvider<UniversityCubit>(
            create: (_) =>
                UniversityCubit()), // Menyediakan UniversityCubit kepada widget tree
      ],
      child: MaterialApp(
        // Memulai aplikasi Flutter
        title: 'Universities List', // Judul aplikasi
        home: Scaffold(
          // Tampilan utama aplikasi
          appBar: AppBar(
            // AppBar di bagian atas
            title: const Text('Indonesian Universities'), // Judul AppBar
          ),
          body: Column(
            // Menampilkan widget secara vertikal
            children: [
              CountrySelector(), // Widget untuk memilih negara ASEAN
              Expanded(
                // Widget untuk menampilkan daftar universitas yang dapat memperluas ruangnya
                child:
                    UniversityList(), // Widget untuk menampilkan daftar universitas
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountrySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final countryCubit = BlocProvider.of<CountryCubit>(
        context); // Mendapatkan akses ke CountryCubit dari widget tree
    final universityCubit = BlocProvider.of<UniversityCubit>(
        context); // Mendapatkan akses ke UniversityCubit dari widget tree

    return BlocBuilder<CountryCubit, String>(
      // Memperbarui widget berdasarkan keadaan CountryCubit
      builder: (context, selectedCountry) {
        return DropdownButton<String>(
          // Menampilkan dropdown untuk memilih negara ASEAN
          value: selectedCountry, // Nilai negara yang dipilih
          onChanged: (String? newValue) {
            // Ketika nilai dropdown berubah
            countryCubit
                .updateCountry(newValue!); // Memperbarui negara yang dipilih
            universityCubit.fetchUniversities(
                newValue); // Mengambil daftar universitas untuk negara yang dipilih
          },
          items: [
            "Indonesia",
            "Malaysia",
            "Singapore",
            "Thailand",
            "Vietnam"
          ] // Daftar negara ASEAN
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }
}

class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityCubit, UniversitiesList>(
      // Memperbarui widget berdasarkan keadaan UniversityCubit
      builder: (context, universitiesList) {
        return universitiesList
                .universities.isEmpty // Jika daftar universitas kosong
            ? Center(
                child:
                    CircularProgressIndicator()) // Tampilkan indikator loading
            : ListView.separated(
                // Tampilkan daftar universitas dengan pemisah antar item
                separatorBuilder: (context, index) => const Divider(),
                itemCount: universitiesList.universities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    // Tampilan untuk setiap item daftar universitas
                    title: Text(universitiesList
                        .universities[index].name), // Judul universitas
                    subtitle: Text(universitiesList
                        .universities[index].website), // Website universitas
                  );
                },
              );
      },
    );
  }
}
