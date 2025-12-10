import 'package:cloud_firestore/cloud_firestore.dart';

void getMedicineWithBrands(String medicineName) async {
  final db = FirebaseFirestore.instance;

  DocumentSnapshot medDoc =
  await db.collection("medicines").doc(medicineName).get();

  if (!medDoc.exists) return;

  print(medDoc["descriptions"]);

  QuerySnapshot brandSnap = await db
      .collection("medicines")
      .doc(medicineName)
      .collection("brands")
      .get();

  for (var brand in brandSnap.docs) {
    print(brand.id);
    print(brand["color"]);
    print(brand["engraved"]);
    print(brand["form"]);
  }
}