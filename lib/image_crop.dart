import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image/image.dart' as imglib;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_share/image_share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
class ImageCropingExample extends StatefulWidget {
  final String title;

  ImageCropingExample({this.title});

  @override
  _ImageCropingExampleState createState() => _ImageCropingExampleState();
}

enum AppState { free, picked,croping, cropped, split }

class _ImageCropingExampleState extends State<ImageCropingExample> {
  AppState state;
  File imageFile;

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            state==AppState.croping?Container():Center(
              child: state == AppState.cropped
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: imageFile != null
                          ? Container(
                        padding: EdgeInsets.all(10),
                            child: GridView.count(
                                // childAspectRatio:
                                crossAxisCount: 3,
                                crossAxisSpacing: 1.5,
                                mainAxisSpacing: 1.5,
                                children: splitImage(imageFile.readAsBytesSync()),
                              ),
                          )
                          : Container(),
                    )
                  : Center(
                      child: imageFile != null
                          ? Image.file(imageFile)
                          : Container(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () {
          if (state == AppState.free)
            _pickImage();
          else if (state == AppState.picked)
            _cropImage();
          else if (state == AppState.cropped)

            splitImage(imageFile.readAsBytesSync());
          else if (state == AppState.split) _clearImage();
        },
        child: _buildButtonIcon(),
      ),
    );
  }

  ///FAB Button Icon
  Widget _buildButtonIcon() {
    if (state == AppState.free)
      return Icon(Icons.add);
    else if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.split)
      return Icon(Icons.clear);
    else
      return Container();
  }

  ///Spliting images in 3x3
  List<Widget> splitImage(List<int> input) {
    imglib.Image image = imglib.decodeImage(imageFile.readAsBytesSync());
    int x = 1, y = 0;
    int width = (image.width / 3).round();
    int height = (image.height / 3).round();

    List<imglib.Image> parts = <imglib.Image>[];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        parts.add(imglib.copyCrop(image, x, y, width, height));
        x += width;
      }
      x = 0;
      y += height;
    }
    List<Widget> output = <Widget>[];
    for (var img in parts) {
      output.add(GestureDetector(
          onTap: () {
            shareImage();
            savingFile(img,);
          },
          child: Image.memory(imglib.encodeJpg(img))));
    }
    return output;
  }

  File filepath;
///Saving file locally
  Future<void> savingFile(imglib.Image img) async {
    var imagePath = imglib.encodeJpg(img);
    final external = (await getExternalStorageDirectory()).path + '/insta.png';
    try {
      final file = File(external);
      filepath = await file.writeAsBytes(imagePath);
    } catch(error) {
      print('///// ERROR: $error');
    }
  }

  ///Converting image to file

  ///Share image
  Future<void> shareImage() async {
    final RenderBox box = context.findRenderObject();
    Share.shareFiles([filepath.path],
        subject: "this is subject",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  /// pick image from camera
  Future<Null> _pickImage() async {
    final pickedImage =
        await ImagePicker().getImage(source: ImageSource.camera);
    imageFile = pickedImage != null ? File(pickedImage.path) : null;
    if (imageFile != null) {
      setState(() {
        state = AppState.picked;
      });
    }
  }

  ///crop image in square
  Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
              ]
            : [
                // CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                // CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio5x3,
                // CropAspectRatioPreset.ratio5x4,
                // CropAspectRatioPreset.ratio7x5,
                // CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      imageFile = croppedFile;
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  ///clear image
  void _clearImage() {
    imageFile = null;
    setState(() {
      state = AppState.free;
    });
  }
}