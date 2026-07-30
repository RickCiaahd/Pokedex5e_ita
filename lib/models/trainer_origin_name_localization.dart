/// Restituisce il nome dell'origine dell'Allenatore nella lingua attiva.
///
/// In inglese vengono mantenuti i nomi aggettivali del manuale; in italiano
/// le origini regionali usano direttamente il nome ufficiale della regione.
String trainerOriginDisplayName(
  String originName, {
  required bool isItalian,
  required String dmApprovedLabel,
}) {
  if (originName == 'Origine 5e approvata dal DM') {
    return dmApprovedLabel;
  }
  if (!isItalian) return originName;

  return switch (originName) {
    'Alolan' => 'Alola',
    'Hoennian' => 'Hoenn',
    'Johtoan' => 'Johto',
    'Kalosian' => 'Kalos',
    'Kantoan' => 'Kanto',
    'Sinnoan' => 'Sinnoh',
    'Unovan' => 'Unima',
    'Galarian' => 'Galar',
    _ => originName,
  };
}
