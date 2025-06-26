import 'package:flutter/material.dart';
import 'package:connectify_app/utils/app_colors.dart'; // Renk paletimiz için

// Filtreleme kriterlerini taşıyacak basit bir sınıf
class FilterCriteria {
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final String? location; // Şimdilik şehir/konum adı

  FilterCriteria({this.minAge, this.maxAge, this.gender, this.location});

  // Filtrelerin boş olup olmadığını kontrol et
  bool get isEmpty =>
      minAge == null && maxAge == null && gender == null && location == null;

  // Filtreleri Map'e dönüştür (kaydetme veya geçiş için)
  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'gender': gender,
      'location': location,
    };
  }

  // Map'ten FilterCriteria oluştur
  static FilterCriteria fromMap(Map<String, dynamic> map) {
    return FilterCriteria(
      minAge: map['minAge'],
      maxAge: map['maxAge'],
      gender: map['gender'],
      location: map['location'],
    );
  }
}

class FilterScreen extends StatefulWidget {
  final FilterCriteria
  initialFilters; // DiscoverScreen'den gelen mevcut filtreler

  const FilterScreen({super.key, required this.initialFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  RangeValues _currentAgeRange = const RangeValues(
    18,
    77,
  ); // Varsayılan yaş aralığı
  String? _selectedGender;
  TextEditingController _locationController = TextEditingController();

  final List<String> _genders = ['Kadın', 'Erkek', 'Belirtmek İstemiyorum'];

  @override
  void initState() {
    super.initState();
    // Başlangıç filtrelerini uygula
    _currentAgeRange = RangeValues(
      widget.initialFilters.minAge?.toDouble() ?? 18,
      widget.initialFilters.maxAge?.toDouble() ?? 77,
    );
    _selectedGender = widget.initialFilters.gender;
    _locationController.text = widget.initialFilters.location ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // Filtreleri sıfırlama
  void _resetFilters() {
    setState(() {
      _currentAgeRange = const RangeValues(18, 77);
      _selectedGender = null; // Cinsiyeti sıfırla
      _locationController.clear();
    });
  }

  // Filtreleri uygulama ve geri gönderme
  void _applyFilters() {
    final FilterCriteria appliedFilters = FilterCriteria(
      minAge: _currentAgeRange.start.round(),
      maxAge: _currentAgeRange.end.round(),
      gender: _selectedGender,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
    );
    Navigator.of(context).pop(appliedFilters); // Filtreleri geri gönder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtreler'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Sıfırla',
              style: TextStyle(color: AppColors.primaryText), // Renk paletinden
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Yaş Aralığı ---
            Text(
              'Yaş Aralığı: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: _currentAgeRange,
              min: 18,
              max: 77,
              divisions: 59, // 18-77 arası (77-18+1)
              labels: RangeLabels(
                _currentAgeRange.start.round().toString(),
                _currentAgeRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _currentAgeRange = values;
                });
              },
              activeColor: AppColors.primaryYellow, // Renk paletinden
              inactiveColor: AppColors.grey.withOpacity(0.5), // Renk paletinden
            ),
            const SizedBox(height: 32),

            // --- Cinsiyet ---
            const Text(
              'Cinsiyet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _genders.map((gender) {
                return ChoiceChip(
                  label: Text(gender),
                  selected: _selectedGender == gender,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedGender = selected
                          ? gender
                          : null; // Sadece tek seçim
                    });
                  },
                  selectedColor: AppColors.accentPink, // Renk paletinden
                  labelStyle: TextStyle(
                    color: _selectedGender == gender
                        ? AppColors.white
                        : AppColors.primaryText, // Renk paletinden
                  ),
                  backgroundColor: AppColors.grey.withOpacity(
                    0.2,
                  ), // Renk paletinden
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // --- Konum ---
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Şehir/Konum',
                hintText: 'Örn: Ankara, İstanbul',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 40),

            // --- Filtreleri Uygula Butonu ---
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Filtreleri Uygula'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow, // Renk paletinden
                foregroundColor: AppColors.black, // Renk paletinden
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
