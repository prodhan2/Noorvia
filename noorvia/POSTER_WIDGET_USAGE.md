# Poster Carousel Widget - ব্যবহার নির্দেশিকা

## 📦 Widget টি কোথায় আছে?
`lib/widgets/poster_carousel_widget.dart`

## ✅ কিভাবে ব্যবহার করবেন?

### সহজ উদাহরণ (Basic Usage):

```dart
import 'package:noorvia/widgets/poster_carousel_widget.dart';

// আপনার যেকোনো screen এ এভাবে ব্যবহার করুন:
const PosterCarouselWidget()
```

### সম্পূর্ণ উদাহরণ (Full Customization):

```dart
const PosterCarouselWidget(
  height: 200,                              // উচ্চতা (default: 200)
  autoSlide: true,                          // অটো স্লাইড চালু/বন্ধ (default: true)
  autoSlideDuration: Duration(seconds: 3),  // স্লাইড সময় (default: 3 seconds)
  showIndicator: true,                      // নিচে ডট দেখাবে (default: true)
  margin: EdgeInsets.all(16),               // চারপাশে মার্জিন
  borderRadius: BorderRadius.circular(16),  // কোণা গোল করা
)
```

## 🎯 বৈশিষ্ট্য (Features):

✅ **API থেকে স্বয়ংক্রিয় লোড** - API থেকে সব poster images load হবে
✅ **অটো স্লাইড** - নিজে নিজে slide হবে (চালু/বন্ধ করা যাবে)
✅ **ম্যানুয়াল স্লাইড** - হাতে swipe করে slide করা যাবে
✅ **ক্লিক করলে Details Page** - যেকোনো poster এ click করলে details page খুলবে
✅ **Loading State** - লোড হওয়ার সময় loading indicator দেখাবে
✅ **Error Handling** - error হলে retry button দেখাবে
✅ **Page Indicator** - নিচে dots দিয়ে কোন page এ আছে দেখাবে
✅ **Pause/Play Button** - উপরে ডানদিকে auto slide চালু/বন্ধ করার button

## 📱 আপনার Home Screen এ যোগ করুন:

```dart
import 'package:flutter/material.dart';
import 'package:noorvia/widgets/poster_carousel_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('হোম')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ এখানে Poster Widget যোগ করুন
            const PosterCarouselWidget(
              height: 200,
              autoSlide: true,
            ),
            
            // আপনার অন্যান্য content
            // ...
          ],
        ),
      ),
    );
  }
}
```

## 🎨 Customization Options:

| Parameter | Type | Default | বর্ণনা |
|-----------|------|---------|--------|
| `height` | double | 200 | Widget এর উচ্চতা |
| `autoSlide` | bool | true | অটো স্লাইড চালু/বন্ধ |
| `autoSlideDuration` | Duration | 3 seconds | কত সময় পর পর slide হবে |
| `showIndicator` | bool | true | নিচে dots দেখাবে কিনা |
| `margin` | EdgeInsets? | EdgeInsets.all(16) | চারপাশে spacing |
| `borderRadius` | BorderRadius? | BorderRadius.circular(16) | কোণা গোল করা |

## 🔧 API Configuration:

API URL: `https://opensheet.elk.sh/16SrsQMW8ETVOzz8J7Ty6HOfWqDU6lAx_ya5bGDxlA5o/2`

যদি API URL পরিবর্তন করতে চান, তাহলে `lib/services/poster_service.dart` file এ গিয়ে `apiUrl` পরিবর্তন করুন।

## 📂 Files Structure:

```
lib/
├── models/
│   └── poster_model.dart           # Poster data model
├── services/
│   └── poster_service.dart         # API service
├── screens/
│   ├── poster_screen.dart          # Full poster screen (optional)
│   └── poster_details_screen.dart  # Details page
└── widgets/
    └── poster_carousel_widget.dart # ✅ Main widget (এটি use করুন)
```

## 💡 Tips:

1. **Internet Permission**: নিশ্চিত করুন যে `AndroidManifest.xml` এ internet permission আছে
2. **Image Caching**: Images automatically cache হয় তাই দ্রুত load হবে
3. **Responsive**: সব screen size এ ভালো দেখাবে
4. **Performance**: Optimized করা আছে smooth scrolling এর জন্য

## 🚀 Quick Start:

1. আপনার screen এ import করুন:
```dart
import 'package:noorvia/widgets/poster_carousel_widget.dart';
```

2. যেখানে দেখাতে চান সেখানে add করুন:
```dart
const PosterCarouselWidget()
```

3. Done! 🎉

## ❓ সমস্যা হলে:

- নিশ্চিত করুন internet connection আছে
- API URL সঠিক আছে কিনা check করুন
- Console এ error message দেখুন
