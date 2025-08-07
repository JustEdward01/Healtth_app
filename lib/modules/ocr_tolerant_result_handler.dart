// Multilingual OCR Error-Tolerant Allergen Detection

class OCRTolerantResultHandler {
  
  /// Detectează alergeni cu toleranță la erori OCR în toate limbile
  List<String> findAllergensWithOCRTolerance(String text) {
    final matches = findAllergensDetailedWithOCRTolerance(text);
    return matches.map((match) => match.allergen).toSet().toList();
  }

  /// Detectare multilingvă cu toleranță la erori OCR
  List<AllergenMatch> findAllergensDetailedWithOCRTolerance(String text) {
    final List<AllergenMatch> matches = [];
    final preprocessedText = _preprocessOCRText(text.toLowerCase());

    // Pattern-uri tolerante la erori OCR pentru TOATE limbile
    final multilingualOCRPatterns = {
      'lapte': [
        // ROMÂNĂ cu erori OCR
        r'\b(l[aă@4][pt][pt][eë3ê]|[il1|][aă@4][pt][pt][eë3ê])\b',              // lapte -> lappe, iapte
        r'\b(l[aă@4]ct[o0ö][sz5][aă@4]|[il1|][aă@4]ct[o0ö][sz5][aă@4])\b',      // lactoza -> lactosa, iactoza
        r'\b(sm[aă@4]nt[aă@4]n[aă@4]|sm[il1|]nt[aă@4]n[aă@4])\b',              // smântână -> smintana
        r'\b(br[aă@4]nz[aă@4]|br[il1|]nz[aă@4])\b',                             // brânză -> brinza
        
        // ENGLEZĂ cu erori OCR
        r'\b(m[il1|][il1|]k|m[il1|]lk|rn[il1|]lk)\b',                           // milk -> miik, millt, rnilk
        r'\b(d[aă@4][il1|]ry|d[aă@4][il1|]ry|da[il1|]ry)\b',                   // dairy -> daity, dairy
        r'\b(l[aă@4]ct[o0ö]s[eë3ê]|l[il1|]ct[o0ö]s[eë3ê])\b',                 // lactose -> lactose, lictose
        r'\b(wh[eë3ê]y|wh[il1|]y|vh[eë3ê]y)\b',                                // whey -> whiy, vhey
        r'\b(c[aă@4]s[eë3ê][il1|]n|c[il1|]s[eë3ê][il1|]n)\b',                 // casein -> casein, cisein
        r'\b(cr[eë3ê][aă@4]m|cr[eë3ê][il1|]m|cr[eë3ê]am)\b',                  // cream -> crearn, creim
        r'\b(ch[eë3ê][eë3ê]s[eë3ê]|ch[eë3ê][il1|]s[eë3ê])\b',               // cheese -> cheise
        r'\b(butt[eë3ê]r|butt[il1|]r|buter)\b',                                // butter -> butier, buter
        
        // GERMANĂ cu erori OCR
        r'\b(m[il1|]lch|m[il1|][il1|]ch|rn[il1|]lch)\b',                       // milch -> miich, rnilch
        r'\b(s[aă@4]hn[eë3ê]|s[il1|]hn[eë3ê])\b',                             // sahne -> sihne
        r'\b(k[aă@4]s[eë3ê]|k[il1|]s[eë3ê])\b',                               // käse -> kise
        r'\b(j[oö0][gq]hurt|j[oö0][gq]hrt)\b',                                 // joghurt -> joghrt
        
        // FRANCEZĂ cu erori OCR
        r'\b(l[aă@4][il1|]t|l[il1|][il1|]t)\b',                                // lait -> liit
        r'\b(cr[eë3ê]m[eë3ê]|cr[eë3ê]rn[eë3ê])\b',                           // crème -> crerne
        r'\b(fr[oö0]m[aă@4][gq][eë3ê]|fr[oö0]rn[aă@4][gq][eë3ê])\b',         // fromage -> frornage
        
        // ITALIANĂ cu erori OCR
        r'\b(l[aă@4]tt[eë3ê]|l[il1]tt[eë3ê])\b',                              // latte -> litte
        r'\b(f[oö0]rm[aă@4][gq][gq][il1|][oö0])\b',                           // formaggio -> forrnaggio
        
        // SPANIOLĂ cu erori OCR
        r'\b(l[eë3ê]ch[eë3ê]|l[il1|]ch[eë3ê])\b',                            // leche -> liche
        r'\b(qu[eë3ê]s[oö0]|qu[il1|]s[oö0])\b',                               // queso -> quiso
      ],
      
      'oua': [
        // ROMÂNĂ cu erori OCR
        r'\b([oö0][uüú][aă@4ä]|[oö0][uüú])\b',                                 // ouă, ou -> oun, oui
        r'\b([oö0][uüú]n|[oö0][uüú][il1|])\b',                                 // ou -> oun, oui
        r'\b([gq][aă@4]lb[eë3ê]nu[șşs]|[gq][il1|]lb[eë3ê]nu[șşs])\b',        // gălbenuș -> gilbenus
        r'\b([aă@4]lbu[șşs]|[il1|]lbu[șşs])\b',                               // albuș -> ilbus
        
        // ENGLEZĂ cu erori OCR
        r'\b([eë3ê][gq][gq][șşs5]?|[eë3ê][gq][gq5])\b',                       // eggs -> eqqs, eqg5
        r'\b([eë3ê][gq][gq]|[il1|][gq][gq])\b',                               // egg -> iqg
        r'\b(y[oö0]lk|y[oö0][il1|]k)\b',                                       // yolk -> yoik
        r'\b([aă@4]lbum[eë3ê]n|[il1|]lbum[eë3ê]n)\b',                        // albumen -> ilbumen
        
        // GERMANĂ cu erori OCR
        r'\b([eë3ê][il1|][eë3ê]r|[eë3ê][il1|]r)\b',                          // eier -> eir
        r'\b([eë3ê][il1|]|[il1|][il1|])\b',                                   // ei -> ii
        r'\b([eë3ê][il1|][gq][eë3ê]lb|[eë3ê][il1|][gq]lb)\b',                // eigelb -> eiqlb
        r'\b([eë3ê][il1|]w[eë3ê][il1|][șşs][șşs]|[eë3ê][il1|]w[eë3ê][il1|]s)\b', // eiweiß -> eiweiss
        
        // FRANCEZĂ cu erori OCR
        r'\b([œoö0][eë3ê]uf[șşs5]?|[oö0][eë3ê]uf[șşs5]?)\b',                 // œufs -> oeufs, oeuf5
        r'\b([oö0][eë3ê]uf|[oö0]uf)\b',                                        // oeuf -> ouf
        r'\b(j[aă@4]un[eë3ê]|j[il1|]un[eë3ê])\b',                             // jaune -> jiune
        r'\b(bl[aă@4]nc|bl[il1|]nc)\b',                                         // blanc -> blinc
        
        // ITALIANĂ cu erori OCR
        r'\b(u[oö0]v[aă@4]|u[oö0]v[oö0])\b',                                   // uova -> uovo
        r'\b(u[oö0]v[oö0]|uv[oö0])\b',                                          // uovo -> uvo
        
        // SPANIOLĂ cu erori OCR
        r'\b(hu[eë3ê]v[oö0][șşs5]?|hu[il1|]v[oö0][șşs5]?)\b',                 // huevos -> huivos
      ],
      
      'grau': [
        // ROMÂNĂ cu erori OCR - grâu, făină, gluten
        r'\b([gq]r[aă@4âä]u|[gq]r[il1|]u)\b',                                  // grâu -> qriu, griu
        r'\b(f[aă@4ä][il1|]n[aă@4ä]|f[il1|][il1|]n[aă@4ä])\b',               // făină -> fiina, filna
        r'\b([gq]lut[eë3ê]n|[gq]lut[il1|]n)\b',                               // gluten -> qluten, glutin
        r'\b([aă@4]m[il1|]d[oö0]n|[il1|]m[il1|]d[oö0]n)\b',                   // amidon -> imidon
        
        // ENGLEZĂ cu erori OCR
        r'\b(wh[eë3ê][aă@4]t|wh[il1|][aă@4]t|vh[eë3ê][aă@4]t)\b',             // wheat -> whiat, vheat
        r'\b(fl[oö0]ur|fl[oö0]wr|f1[oö0]ur)\b',                               // flour -> flowr, f1our
        r'\b([gq]lut[eë3ê]n|[gq]lut[il1|]n)\b',                               // gluten -> qluten, glutin
        r'\b([șşs]t[aă@4]rch|st[il1|]rch)\b',                                  // starch -> stirch
        
        // GERMANĂ cu erori OCR
        r'\b(w[eë3ê][il1|]z[eë3ê]n|w[il1|][il1|]z[eë3ê]n)\b',                // weizen -> weizen, wiizen
        r'\b(m[eë3ê]hl|m[il1|]hl)\b',                                          // mehl -> mihl
        r'\b([gq]lut[eë3ê]n|[gq]lut[il1|]n)\b',                               // gluten -> qluten
        r'\b([șşs]t[aă@4]rk[eë3ê]|st[il1|]rk[eë3ê])\b',                       // stärke -> stirke
        
        // FRANCEZĂ cu erori OCR
        r'\b(bl[eë3ê]|b1[eë3ê])\b',                                            // blé -> ble, b1e
        r'\b(f[aă@4]r[il1|]n[eë3ê]|f[il1|]r[il1|]n[eë3ê])\b',                // farine -> firine
        r'\b([gq]lut[eë3ê]n|[gq]lut[il1|]n)\b',                               // gluten -> qluten
        
        // ITALIANĂ cu erori OCR
        r'\b(frum[eë3ê]nt[oö0]|frum[il1|]nt[oö0])\b',                          // frumento -> fruminto
        r'\b(f[aă@4]r[il1|]n[aă@4]|f[il1|]r[il1|]n[aă@4])\b',                 // farina -> firina
        
        // SPANIOLĂ cu erori OCR
        r'\b(tr[il1|][gq][oö0]|tr[il1|][gq]o)\b',                              // trigo -> triqqo
        r'\b(h[aă@4]r[il1|]n[aă@4]|h[il1|]r[il1|]n[aă@4])\b',                 // harina -> hirina
      ],
      
      'soia': [
        // ROMÂNĂ cu erori OCR
        r'\b([șşs][oö0][il1|][aă@4]|s[oö0]y[aă@4])\b',                         // soia -> soyia, soia
        r'\b(l[eë3ê]c[il1|]t[il1|]n[aă@4]|l[il1|]c[il1|]t[il1|]n[aă@4])\b',   // lecitină -> licitina
        
        // ENGLEZĂ cu erori OCR
        r'\b([șşs][oö0]y|s[oö0]y[aă@4])\b',                                    // soy -> soya
        r'\b([șşs][oö0]yb[eë3ê][aă@4]n[șşs5]?|s[oö0]yb[il1|]n[șşs5]?)\b',     // soybeans -> soybians
        r'\b(l[eë3ê]c[il1|]th[il1|]n|l[il1|]c[il1|]th[il1|]n)\b',              // lecithin -> licithin
        r'\b(t[oö0]fu|t[oö0]f[uüú])\b',                                         // tofu -> tofu
        
        // GERMANĂ cu erori OCR
        r'\b([șşs][oö0]j[aă@4]|s[oö0]j[il1|])\b',                              // soja -> sojia
        r'\b([șşs][oö0]j[aă@4]l[eë3ê]c[il1|]th[il1|]n)\b',                     // sojalecithin
        
        // FRANCEZĂ cu erori OCR
        r'\b([șşs][oö0]j[aă@4]|s[oö0]j[il1|])\b',                              // soja -> sojia
        r'\b(l[eë3êé]c[il1|]th[il1|]n[eë3ê])\b',                               // lécithine -> licithiné
        
        // ITALIANĂ cu erori OCR
        r'\b([șşs][oö0][il1|][aă@4]|s[oö0]y[il1|])\b',                         // soia -> soyia
      ],
      
      'nuci': [
        // ROMÂNĂ cu erori OCR
        r'\b(nuc[il1|]|nu[cç][il1|])\b',                                        // nuci -> nuci, nuçi
        r'\b([aă@4]lun[eë3ê]|[il1|]lun[eë3ê])\b',                             // alune -> ilune
        r'\b(m[il1|][gq]d[aă@4]l[eë3ê]|m[aă@4][gq]d[il1|]l[eë3ê])\b',        // migdale -> miqdile
        r'\b(c[aă@4][șşs]t[aă@4]n[eë3ê]|c[il1|]st[il1|]n[eë3ê])\b',           // castane -> cistine
        r'\b(f[il1|][șşs]t[il1|]c|f[aă@4]st[il1|]c)\b',                        // fistic -> fistic
        
        // ENGLEZĂ cu erori OCR
        r'\b(nut[șşs5]?|nu[tţ][șşs5]?)\b',                                      // nuts -> nut5, nuţs
        r'\b([aă@4]lm[oö0]nd[șşs5]?|[il1|]lm[oö0]nd[șşs5]?)\b',               // almonds -> ilmonds
        r'\b(h[aă@4]z[eë3ê]lnut[șşs5]?|h[il1|]z[il1|]lnut[șşs5]?)\b',         // hazelnuts -> hizelnut5
        r'\b(w[aă@4]lnut[șşs5]?|w[il1|]lnut[șşs5]?)\b',                        // walnuts -> wilnut5
        r'\b(c[aă@4][șşs]h[eë3ê]w[șşs5]?|c[il1|]sh[il1|]w[șşs5]?)\b',         // cashews -> cishiw5
        r'\b(p[eë3ê]c[aă@4]n[șşs5]?|p[il1|]c[il1|]n[șşs5]?)\b',               // pecans -> picin5
        r'\b(p[il1|][șşs]t[aă@4]ch[il1|][oö0][șşs5]?)\b',                      // pistachios -> pistichios
        
        // GERMANĂ cu erori OCR
        r'\b(nü[șşs][șşs][eë3ê]|nu[șşs][șşs][eë3ê])\b',                       // nüsse -> nusse
        r'\b(m[aă@4]nd[eë3ê]ln|m[il1|]nd[il1|]ln)\b',                          // mandeln -> mindeln
        r'\b(h[aă@4][șşs][eë3ê]lnü[șşs][șşs][eë3ê])\b',                       // haselnüsse
        r'\b(w[aă@4]lnü[șşs][șşs][eë3ê]|w[il1|]lnu[șşs][șşs][eë3ê])\b',       // walnüsse -> wilnusse
        
        // FRANCEZĂ cu erori OCR
        r'\b(n[oö0][il1|]x|n[oö0][aă@4]x)\b',                                   // noix -> noiax
        r'\b([aă@4]m[aă@4]nd[eë3ê][șşs5]?|[il1|]m[il1|]nd[eë3ê][șşs5]?)\b',   // amandes -> imindes
        r'\b(n[oö0][il1|][șşs]ett[eë3ê][șşs5]?)\b',                            // noisettes -> noisette5
        
        // ITALIANĂ cu erori OCR
        r'\b(n[oö0]c[il1|]|n[aă@4]c[il1|])\b',                                 // noci -> naci
        r'\b(m[aă@4]nd[oö0]rl[eë3ê]|m[il1|]nd[oö0]rl[il1|])\b',               // mandorle -> mindorle
        
        // SPANIOLĂ cu erori OCR
        r'\b(nu[eë3ê]c[eë3ê][șşs5]?|nu[il1|]c[il1|][șşs5]?)\b',               // nueces -> nuices
        r'\b([aă@4]lm[eë3ê]ndr[aă@4][șşs5]?|[il1|]lm[il1|]ndr[il1|][șşs5]?)\b', // almendras -> ilmindris
      ],
      
      'peste': [
        // ROMÂNĂ cu erori OCR
        r'\b(p[eë3ê][șşs]t[eë3ê]|p[il1|]st[il1|])\b',                         // pește -> piste
        r'\b(p[eë3ê][șşs]t[il1|]|p[il1|]st[eë3ê])\b',                         // pești -> pesti
        r'\b(t[oö0]n|t[aă@4]n)\b',                                             // ton -> tan
        r'\b([șşs][aă@4]lm[oö0]n|s[il1|]lm[oö0]n)\b',                         // somon -> silmon
        
        // ENGLEZĂ cu erori OCR
        r'\b(f[il1|][șşs]h|f[il1|]sh)\b',                                      // fish -> fiyh, filsh
        r'\b(tun[aă@4]|tun[il1|])\b',                                          // tuna -> tunia
        r'\b([șşs][aă@4]lm[oö0]n|s[il1|]lm[oö0]n)\b',                         // salmon -> silmon
        r'\b(c[oö0]d|c[aă@4]d)\b',                                             // cod -> cad
        r'\b([șşs][aă@4]rd[il1|]n[eë3ê][șşs5]?|s[il1|]rd[il1|]n[il1|][șşs5]?)\b', // sardines -> sirdin5
        
        // GERMANĂ cu erori OCR
        r'\b(f[il1|][șşs]ch|f[il1|]sch)\b',                                    // fisch -> filsch
        r'\b(thunf[il1|][șşs]ch|thunf[il1|]sch)\b',                           // thunfisch -> thunfilsch
        r'\b(l[aă@4]ch[șşs5]?|l[il1|]ch[șşs5]?)\b',                           // lachs -> lich5
        
        // FRANCEZĂ cu erori OCR
        r'\b(p[oö0][il1|][șşs][șşs][oö0]n|p[aă@4][il1|]s[oö0]n)\b',           // poisson -> poison
        r'\b(th[oö0]n|th[aă@4]n)\b',                                           // thon -> than
        r'\b([șşs][aă@4]um[oö0]n|s[il1|]um[oö0]n)\b',                         // saumon -> siumon
        
        // ITALIANĂ cu erori OCR
        r'\b(p[eë3ê][șşs]c[eë3ê]|p[il1|]sc[il1|])\b',                         // pesce -> pisce
        r'\b(t[oö0]nn[oö0]|t[aă@4]nn[aă@4])\b',                               // tonno -> tanna
        
        // SPANIOLĂ cu erori OCR
        r'\b(p[eë3ê][șşs]c[aă@4]d[oö0]|p[il1|]sc[il1|]d[aă@4])\b',           // pescado -> piscida
        r'\b([aă@4]tún|[il1|]tun)\b',                                          // atún -> itun
      ],
    };

    // Context negativ multilingv
    final hasNegativeContext = _hasMultilingualNegativeContext(preprocessedText);

    for (final entry in multilingualOCRPatterns.entries) {
      final allergen = entry.key;
      
      for (final pattern in entry.value) {
        final regex = RegExp(pattern, caseSensitive: false);
        
        for (final match in regex.allMatches(preprocessedText)) {
          final foundTerm = match.group(0)!;
          final position = match.start;
          
          double confidence = _calculateMultilingualOCRConfidence(
            preprocessedText, 
            foundTerm, 
            allergen,
            hasNegativeContext,
          );
          
          if (confidence > 0.4) {
            matches.add(AllergenMatch(
              allergen: allergen,
              foundTerm: foundTerm,
              confidence: confidence,
              position: position,
            ));
          }
        }
      }
    }

    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _removeDuplicates(matches);
  }

  /// Preprocessing multilingv pentru text OCR
  String _preprocessOCRText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s,;:\.\-\(\)%àâäéèêëïîôöùûüÿçăâîșțñáéíóúüßäöüąćęłńóśźżœ]'), '')
        .trim();
  }

  /// Context negativ multilingv
  bool _hasMultilingualNegativeContext(String text) {
    final negativePatterns = [
      // Română
      r'\b(f[aă@4]r[aă@4]|f[il1|]r[aă@4]|nu\s+c[oö0]nt[il1|]n[eë3ê])\b',
      // Engleză
      r'\b(w[il1|]th[oö0]ut|fr[eë3ê][eë3ê]|d[oö0][eë3ê][șşs5]\s+n[oö0]t\s+c[oö0]nt[aă@4][il1|]n)\b',
      // Germană
      r'\b([oö0]hn[eë3ê]|fr[eë3ê][il1|]|[eë3ê]nth[aă@4]lt\s+k[eë3ê][il1|]n)\b',
      // Franceză
      r'\b([șşs][aă@4]n[șşs5]|[șşs][aă@4]ns|n[eë3ê]\s+c[oö0]nt[il1|][eë3ê]nt\s+p[aă@4][șşs5])\b',
      // Italiană
      r'\b([șşs][eë3ê]nz[aă@4]|n[oö0]n\s+c[oö0]nt[il1|][eë3ê]n[eë3ê])\b',
      // Spaniolă
      r'\b([șşs][il1|]n|n[oö0]\s+c[oö0]nt[il1|][eë3ê]n[eë3ê])\b',
      // Pattern-uri generale "free"
      r'-fr[eë3ê][eë3ê]\b',
      r'fr[eë3ê][il1|]\b',
    ];
    
    return negativePatterns.any((pattern) => 
        RegExp(pattern, caseSensitive: false).hasMatch(text));
  }

  /// Calculează confidence multilingv
  double _calculateMultilingualOCRConfidence(String text, String foundTerm, String allergen, bool hasNegative) {
    double confidence = 0.65;
    
    if (hasNegative) confidence -= 0.4;
    if (_hasMultilingualIngredientContext(text)) confidence += 0.25;
    if (foundTerm.length >= 4) confidence += 0.1;
    if (_nearMultilingualKeywords(text, foundTerm)) confidence += 0.15;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Context ingrediente multilingv
  bool _hasMultilingualIngredientContext(String text) {
    final contextPatterns = [
      // Română
      r'\b[il1|]ngr[eë3ê]d[il1|][eë3ê]nt[eë3ê]',
      r'\bc[oö0]nt[il1|]n[eë3ê]',
      // Engleză
      r'\b[il1|]ngr[eë3ê]d[il1|][eë3ê]nt[șşs5]?',
      r'\bc[oö0]nt[aă@4][il1|]n[șşs5]?',
      // Germană
      r'\bzut[aă@4]t[eë3ê]n',
      r'\b[eë3ê]nth[aă@4]lt',
      // Franceză
      r'\b[il1|]ngr[eë3êé]d[il1|][eë3ê]nt[șşs5]?',
      r'\bc[oö0]nt[il1|][eë3ê]nt',
      // Italiană
      r'\b[il1|]ngr[eë3ê]d[il1|][eë3ê]nt[il1|]',
      r'\bc[oö0]nt[il1|][eë3ê]n[eë3ê]',
      // Spaniolă
      r'\b[il1|]ngr[eë3ê]d[il1|][eë3ê]nt[eë3ê][șşs5]?',
      r'\bc[oö0]nt[il1|][eë3ê]n[eë3ê]',
    ];
    
    return contextPatterns.any((pattern) => 
        RegExp(pattern, caseSensitive: false).hasMatch(text));
  }

  /// Proximitate cu cuvinte cheie multilingve
  bool _nearMultilingualKeywords(String text, String term) {
    final termIndex = text.indexOf(term);
    if (termIndex == -1) return false;
    
    final start = (termIndex - 30).clamp(0, text.length);
    final end = (termIndex + term.length + 30).clamp(0, text.length);
    final context = text.substring(start, end);
    
    final keywordPatterns = [
      // Română
      r'[il1|]ngr[eë3ê]d', r'c[oö0]nt', r'f[aă@4][il1|]n', r'z[aă@4]h[aă@4]r',
      // Engleză  
      r'[il1|]ngr[eë3ê]d', r'c[oö0]nt', r'fl[oö0]ur', r'[șşs]ug[aă@4]r',
      // Germană
      r'zut[aă@4]t', r'[eë3ê]nth', r'm[eë3ê]hl', r'zuck[eë3ê]r',
      // Franceză
      r'[il1|]ngr[eë3êé]d', r'c[oö0]nt', r'f[aă@4]r[il1|]n', r'[șşs]ucr[eë3ê]',
      // Italiană
      r'[il1|]ngr[eë3ê]d', r'c[oö0]nt', r'f[aă@4]r[il1|]n', r'zucch[eë3ê]r',
      // Spaniolă
      r'[il1|]ngr[eë3ê]d', r'c[oö0]nt', r'h[aă@4]r[il1|]n', r'[aă@4]zuc[aă@4]r',
    ];
    
    return keywordPatterns.any((pattern) => 
        RegExp(pattern, caseSensitive: false).hasMatch(context));
  }

  /// Elimină duplicatele
  List<AllergenMatch> _removeDuplicates(List<AllergenMatch> matches) {
    final Map<String, AllergenMatch> uniqueMatches = {};
    
    for (final match in matches) {
      if (!uniqueMatches.containsKey(match.allergen) || 
          uniqueMatches[match.allergen]!.confidence < match.confidence) {
        uniqueMatches[match.allergen] = match;
      }
    }
    
    return uniqueMatches.values.toList();
  }

  /// Obține alergenii disponibili
  List<String> get availableAllergens => ['lapte', 'oua', 'grau', 'soia', 'nuci', 'peste'];
}

class AllergenMatch {
  final String allergen;
  final String foundTerm;
  final double confidence;
  final int position;

  AllergenMatch({
    required this.allergen,
    required this.foundTerm,
    required this.confidence,
    required this.position,
  });
}

// Test multilingv
void main() {
  final detector = OCRTolerantResultHandler();
  
  // Teste multilingve cu erori OCR
  final testCases = [
    // Română cu erori OCR
    'ingrediente fiina de grau zahl ingrediente filnm oun integrol apls sare bente',
    'conține: lnpte, oua, soin',
    
    // Engleză cu erori OCR  
    'ingredients: flour, miik, eqgs, soy lecithin',
    'contains: wheat f1our, dairy, nuts',
    
    // Germană cu erori OCR
    'zutaten: weizen, miich, eier, soja',
    'enthält: mehl, milch, nüsse',
    
    // Franceză cu erori OCR
    'ingrédients: farine, lait, oeufs, soja',
    'contient: blé, fromaqe, noix',
    
    // Italiană cu erori OCR
    'ingredienti: farina, latte, uova, soia',
    'contiene: frumento, formaggio, noci',
    
    // Spaniolă cu erori OCR
    'ingredientes: harina, leche, huevos, soja',
    'contiene: trigo, queso, nueces',
    
    // Mixte cu erori OCR
    'ingredients/ingrediente: wheat flour/faina de grau, milk/lnpte, eqgs/oua',
  ];
  
  print('=== TEST MULTILINGUAL OCR TOLERANCE ===');
  for (int i = 0; i < testCases.length; i++) {
    final testText = testCases[i];
    final results = detector.findAllergensWithOCRTolerance(testText);
    
    print('\nTest ${i + 1}:');
    print('Text: "$testText"');
    print('Alergeni: $results');
    
    if (results.isNotEmpty) {
      final detailed = detector.findAllergensDetailedWithOCRTolerance(testText);
      for (final match in detailed.take(3)) {
        print('  → ${match.allergen}: "${match.foundTerm}" (${match.confidence.toStringAsFixed(2)})');
      }
    }
  }
  
  print('\n=== TEST NEGATIVE CONTEXT ===');
  final negativeCases = [
    'fără lapte, gluten-free',
    'lactose-free, ohne milch', 
    'sans gluten, dairy-free',
    'senza glutine, sin leche',
  ];
  
  for (final negTest in negativeCases) {
    final results = detector.findAllergensWithOCRTolerance(negTest);
    print('Negativ: "$negTest" → $results (should be empty)');
  }
}