import 'package:flutter/material.dart';

class SliderWidget extends StatefulWidget {
  final bool isOpen;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> activities;
  final VoidCallback onClose;

  const SliderWidget({
    Key? key,
    required this.isOpen,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.activities,
    required this.onClose,
  }) : super(key: key);

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  bool isActivitiesOpen = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant SliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen && widget.isOpen) {
      Future.delayed(Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        setState(() {
          isActivitiesOpen = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double sliderWidth =
        screenWidth * 0.8; 
    double sliderHeight = screenHeight;

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      top: 0, 
      bottom: 0,
      left: widget.isOpen
          ? screenWidth * 0.1
          : -sliderWidth, 
      right: widget.isOpen ? 0 : -sliderWidth, 
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: sliderWidth,
        height: sliderHeight,
        color: Colors.white,
        child: Column(
          children: [
            
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              color: Colors.blue,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Fotoğraf Alanı
            SizedBox(
              height: screenHeight * 0.3,
              child: widget.imageUrl.isNotEmpty
                  ? widget.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          widget.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                  : Container(
                      color: Colors.grey[300],
                      child: Center(
                          child: Text("Fotoğraf Yok",
                              style: TextStyle(fontSize: 16)))),
            ),

            // Scrollable İçerik Alanı
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Açılıp Kapanabilen Açıklama (Varsayılan Açık)
                      ExpansionTile(
                        initiallyExpanded:
                            true,
                        title: Text(
                          "Description",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              widget.description,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Açılıp Kapanabilen Activities
                      ExpansionTile(
                        title: Text(
                          "Activities",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        children: widget.activities.map((activity) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child:
                                Text(activity, style: TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
