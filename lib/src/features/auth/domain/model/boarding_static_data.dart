final walkthroughList = [
  WalkthroughData(
    title: "Discover Your Next Adventure",
    description:
        "Tripify curates travel gems just for you. Get personalized destination recommendations and start building your dream journey.",
    image: "assets/images/on_boarding1.png",
  ),
  WalkthroughData(
    title: "Save and Plan Your Adventures",
    description:
        "Found your dream destination? Add it to your saved list for later. Tripify keeps your travel dreams organized and within reach.",
    image: "assets/images/on_boarding2.png",
  ),
  WalkthroughData(
    title: "Intelligent Trip Planning with Tripify AI",
    description:
        "Let our AI plan a detailed trip tailored to your preferences. Easy planning for your unforgettable experience.",
    image: "assets/images/on_boarding3.png",
  ),
];

class WalkthroughData {
  final String title;
  final String description;
  final String image;

  WalkthroughData({
    required this.title,
    required this.description,
    required this.image,
  });
}
