
class OnboardingContents {
  final String title;
  final String image;
  final String desc;

  OnboardingContents({
    required this.title,
    required this.image,
    required this.desc,
  });
}

List<OnboardingContents> contents = [
  OnboardingContents(
    title: "Сжигайте жир",
    image: "assets/images/image1.png",
    desc: "Продолжайте тренироваться, чтобы достичь своих целей. Боль временная, если вы сдадитесь сейчас, боль будет вечной",
  ),
  OnboardingContents(
    title: "Питайтесь правильно",
    image: "assets/images/image2.png",
    desc:
    "Давайте начнём здоровый образ жизни вместе с нами. Мы можем составить для вас рацион на каждый день. Здоровое питание — это здорово.",
  ),
  OnboardingContents(
    title: "Улучшите качество сна",
    image: "assets/images/image3.png",
    desc:
    "Улучшите качество своего сна вместе с нами. Хороший сон может подарить хорошее настроение по утрам.",
  ),
];