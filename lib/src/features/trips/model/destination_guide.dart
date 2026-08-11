class DestinationGuide {
  final String city;
  final String country;
  final String flagEmoji;
  final String imageUrl;
  final String description;
  final List<String> gallery;
  final List<MapEntry<String, String>> sections;

  const DestinationGuide({
    required this.city,
    required this.country,
    required this.flagEmoji,
    required this.imageUrl,
    required this.description,
    required this.gallery,
    required this.sections,
  });

  static DestinationGuide getGuideForCity(String cityName) {
    final searchName = cityName.toLowerCase();
    if (searchName.contains('tokyo')) {
      return _tokyoGuide;
    } else if (searchName.contains('paris')) {
      return _parisGuide;
    } else if (searchName.contains('london')) {
      return _londonGuide;
    } else if (searchName.contains('new york')) {
      return _newYorkGuide;
    }
    // Default fallback to Tokyo
    return _tokyoGuide;
  }

  static const DestinationGuide _tokyoGuide = DestinationGuide(
    city: 'Tokyo, Tokyo',
    country: 'Japan',
    flagEmoji: '🇯🇵',
    imageUrl:
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
    description:
        'Discover the vibrant metropolis of Tokyo, where modernity meets tradition in perfect harmony. From futuristic skyscrapers to serene temples and lush parks, Tokyo offers an eclectic blend of experiences.',
    gallery: [
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400', // Shibuya
      'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400', // Pagoda
      'https://images.unsplash.com/photo-1490761902485-a7f4e724e857?w=400', // Mt Fuji
    ],
    sections: [
      MapEntry(
        'Getting to Tokyo:',
        'Tokyo is easily accessible via Narita International Airport (NRT) and Haneda Airport (HND). Direct flights from major cities make it a convenient destination for travelers.',
      ),
      MapEntry(
        'Best Time to Visit:',
        'Tokyo is a year-round destination, but spring (March to May) and autumn (September to November) are the best times to enjoy pleasant weather and stunning cherry blossoms or colorful foliage.',
      ),
      MapEntry(
        'Must-See Attractions:',
        'Explore Tokyo\'s top attractions, including the historic Senso-ji Temple, bustling Shibuya Crossing, the Imperial Palace, and the futuristic Tokyo Skytree.',
      ),
      MapEntry(
        'Local Cuisine:',
        'Indulge in mouthwatering dishes like sushi, ramen, tempura, and okonomiyaki. Don\'t forget to try street food in places like Tsukiji Fish Market.',
      ),
      MapEntry(
        'Activities and Experiences:',
        'Dive into Tokyo\'s culture with activities like tea ceremonies, sumo wrestling matches, and exploring traditional neighborhoods like Asakusa.',
      ),
      MapEntry(
        'Accommodations:',
        'Tokyo offers a range of accommodations, from luxury hotels in Ginza to budget-friendly hostels in Asakusa. Choose a location that suits your travel style.',
      ),
      MapEntry(
        'Transportation:',
        'Tokyo boasts an efficient public transportation system, including the subway and JR trains. Consider purchasing a Japan Rail Pass for convenient travel within the city and beyond.',
      ),
      MapEntry(
        'Safety and Health Tips:',
        'Tokyo is known for its safety, but it\'s essential to stay vigilant. Ensure you have travel insurance, know emergency numbers, and respect local customs.',
      ),
      MapEntry(
        'Local Language:',
        'Learning a few Japanese phrases can enhance your experience. Start with common greetings like \'Konnichiwa\' (Hello) and \'Arigatou gozaimasu\' (Thank you).',
      ),
      MapEntry(
        'Currency:',
        'Japan\'s currency is the yen (¥). Credit cards are widely accepted, but it\'s a good idea to have some cash on hand for small purchases.',
      ),
      MapEntry(
        'Visa and Entry Requirements:',
        'Check the visa requirements for your nationality before traveling to Japan. Many countries have visa-free access for short stays.',
      ),
    ],
  );

  static const DestinationGuide _parisGuide = DestinationGuide(
    city: 'Paris, Paris',
    country: 'France',
    flagEmoji: '🇫🇷',
    imageUrl:
        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
    description:
        'Experience the romance and elegance of Paris, the City of Light. Renowned for its world-class art, fashion, gastronomy, and culture, Paris offers an unforgettable journey into history and beauty.',
    gallery: [
      'https://images.unsplash.com/photo-1499856871958-5b9647a640d0?w=400', // Notre dame
      'https://images.unsplash.com/photo-1431274172761-fca41d930114?w=400', // Parisian balcony
      'https://images.unsplash.com/photo-1522083165195-342750297f46?w=400', // Louvre
    ],
    sections: [
      MapEntry(
        'Getting to Paris:',
        'Paris is served by two major airports: Charles de Gaulle (CDG) and Orly (ORY). High-speed trains connect Paris to major cities across Europe.',
      ),
      MapEntry(
        'Best Time to Visit:',
        'Spring (April to June) and autumn (September to October) offer the most pleasant weather and fewer crowds to explore the city.',
      ),
      MapEntry(
        'Must-See Attractions:',
        'Visit the iconic Eiffel Tower, the Louvre Museum, Notre-Dame Cathedral, and the Arc de Triomphe.',
      ),
      MapEntry(
        'Local Cuisine:',
        'Savor fresh croissants, baguettes, escargot, and delicate macarons. Enjoy dining at cozy bistros and world-class Michelin-starred restaurants.',
      ),
      MapEntry(
        'Activities and Experiences:',
        'Stroll along the Seine River, explore the artistic streets of Montmartre, and enjoy a cruise under the city\'s historic bridges.',
      ),
      MapEntry(
        'Accommodations:',
        'Choose from luxurious hotels in the 1st Arrondissement to boutique guesthouses in the Marais or budget-friendly hostels.',
      ),
      MapEntry(
        'Transportation:',
        'The Paris Metro is fast, efficient, and easy to navigate. Walking is also one of the best ways to see the city\'s beautiful architecture.',
      ),
      MapEntry(
        'Safety and Health Tips:',
        'Paris is generally safe, but watch out for pickpockets in crowded tourist spots and on public transport.',
      ),
      MapEntry(
        'Local Language:',
        'Learning basic French phrases like \'Bonjour\' (Hello) and \'Merci\' (Thank you) is highly appreciated by locals.',
      ),
      MapEntry(
        'Currency:',
        'France uses the Euro (€). Credit cards are widely accepted, but keep some coins for bakeries and small cafes.',
      ),
      MapEntry(
        'Visa and Entry Requirements:',
        'France is part of the Schengen Area. Ensure your passport is valid and check if you need a Schengen visa.',
      ),
    ],
  );

  static const DestinationGuide _londonGuide = DestinationGuide(
    city: 'London, London',
    country: 'United Kingdom',
    flagEmoji: '🇬🇧',
    imageUrl:
        'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800',
    description:
        'Explore the historic and cosmopolitan capital of London. From royal palaces and ancient towers to modern skyscrapers and world-renowned theaters, London is a city of endless discovery.',
    gallery: [
      'https://images.unsplash.com/photo-1529655683826-0957459035c9?w=400', // Big Ben close up
      'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400', // London general
      'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=400', // Red phone boxes
    ],
    sections: [
      MapEntry(
        'Getting to London:',
        'London is connected globally via Heathrow (LHR), Gatwick (LGW), and other airports. High-speed Eurostar trains link London directly with Paris and Brussels.',
      ),
      MapEntry(
        'Best Time to Visit:',
        'Late spring (May to June) and summer (July to August) offer warm weather and longer daylight hours to enjoy the city\'s parks and outdoor markets.',
      ),
      MapEntry(
        'Must-See Attractions:',
        'Do not miss the British Museum, the Tower of London, Buckingham Palace, and the iconic London Eye.',
      ),
      MapEntry(
        'Local Cuisine:',
        'Try traditional fish and chips, a hearty Sunday roast, and classic afternoon tea with scones and clotted cream.',
      ),
      MapEntry(
        'Activities and Experiences:',
        'Watch a West End musical, walk along the South Bank of the Thames, and explore the street food markets in Camden or Borough.',
      ),
      MapEntry(
        'Accommodations:',
        'Accommodations range from upscale hotels in Mayfair to trendy boutique stays in Shoreditch and cozy bed & breakfasts.',
      ),
      MapEntry(
        'Transportation:',
        'Use the London Underground (the Tube) and the famous red double-decker buses. Pay easily using contactless cards or an Oyster card.',
      ),
      MapEntry(
        'Safety and Health Tips:',
        'London is a safe city, but always look both ways when crossing the street, as traffic drives on the left!',
      ),
      MapEntry(
        'Local Language:',
        'English is the official language. You\'ll encounter a rich variety of global accents and dialects.',
      ),
      MapEntry(
        'Currency:',
        'The currency is the British Pound Sterling (£). Most places are cashless, so card payment is preferred everywhere.',
      ),
      MapEntry(
        'Visa and Entry Requirements:',
        'Check entry guidelines post-Brexit. Many nationalities do not require a visa for tourist stays up to 6 months.',
      ),
    ],
  );

  static const DestinationGuide _newYorkGuide = DestinationGuide(
    city: 'New York, New York',
    country: 'United States',
    flagEmoji: '🇺🇸',
    imageUrl:
        'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
    description:
        'Feel the unparalleled energy of New York City, the Big Apple. A global hub of culture, entertainment, art, and finance, NYC boasts iconic landmarks and vibrant neighborhoods that never sleep.',
    gallery: [
      'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=400', // Brooklyn bridge view
      'https://images.unsplash.com/photo-1518391846015-55a9cc003b25?w=400', // Times sq taxi
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400', // Central park
    ],
    sections: [
      MapEntry(
        'Getting to New York:',
        'NYC is served by three major airports: John F. Kennedy (JFK), LaGuardia (LGA), and Newark (EWR). Extensive train systems connect it to the rest of the East Coast.',
      ),
      MapEntry(
        'Best Time to Visit:',
        'Autumn (September to November) offers crisp weather and stunning foliage in Central Park. The holiday season in December is also magical.',
      ),
      MapEntry(
        'Must-See Attractions:',
        'See the Statue of Liberty, Empire State Building, Times Square, and the vast landscapes of Central Park.',
      ),
      MapEntry(
        'Local Cuisine:',
        'Indulge in classic New York-style pizza slices, bagels with lox, hot dogs from street carts, and world-class fine dining.',
      ),
      MapEntry(
        'Activities and Experiences:',
        'Catch a Broadway show, walk across the Brooklyn Bridge, and visit museums like the Met and MoMA.',
      ),
      MapEntry(
        'Accommodations:',
        'Stays range from luxury hotels in Midtown Manhattan to boutique hotels in SoHo and budget options in Long Island City.',
      ),
      MapEntry(
        'Transportation:',
        'The NYC Subway runs 24/7 and is the fastest way to get around. Yellow cabs and ride-sharing apps are also readily available.',
      ),
      MapEntry(
        'Safety and Health Tips:',
        'Stay aware of your surroundings, especially at night. Stick to well-lit, populated streets and subway cars.',
      ),
      MapEntry(
        'Local Language:',
        'English is primary, but New York is one of the most linguistically diverse cities in the world, with over 800 languages spoken.',
      ),
      MapEntry(
        'Currency:',
        'The currency is the US Dollar (\$). Credit and debit cards are accepted almost everywhere, but carry some cash for tipping.',
      ),
      MapEntry(
        'Visa and Entry Requirements:',
        'Most international travelers must apply for an ESTA (Electronic System for Travel Authorization) or obtain a US tourist visa.',
      ),
    ],
  );
}
