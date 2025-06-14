import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/utils/theme.dart';
import 'package:nuance/widgets/custom_dialog.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/loader.dart';

final GlobalKey<ScaffoldState> lobalKey = GlobalKey();

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final sessionData = ref.read(sessionProvider.notifier);
    var nameController = TextEditingController();

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          ref.invalidate(historyProvider);
        }
      },
      child: SafeArea(
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          key: lobalKey,
          drawerEnableOpenDragGesture: true,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 10.0,
                child: Image.asset(
                  "assets/backbtn.png",
                  height: 40.0,
                  width: 40.0,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Profile",
                  style: headingTextStyle,
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            centerTitle: false,
          ),
          body: sessionState.when(
            data: (data) {
              if (data == null) {
                return Center(
                  child: Text(
                    'No user data available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }

              nameController.text = data.user["user_metadata"]["full_name"];

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: sessionState.when(
                              data: (data) {
                                if (data == null) {
                                  return GestureDetector(
                                    child: Container(
                                      width: 140.0,
                                      height: 140.0,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.orange,
                                            Color.fromARGB(255, 255, 222, 59),
                                            Color.fromARGB(255, 225, 153, 47),
                                            Colors.red,
                                          ],
                                        ),
                                        color: Colors.orange,
                                      ),
                                    ),
                                    onTap: () {},
                                  );
                                }

                                return CupertinoButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {},
                                  child: CachedNetworkImage(
                                    imageBuilder: (context, imageProvider) =>
                                        CircleAvatar(
                                      radius: 70,
                                      backgroundImage: imageProvider,
                                      backgroundColor: Colors.grey,
                                    ),
                                    fit: BoxFit.fill,
                                    height: 150,
                                    imageUrl: data.user["user_metadata"]
                                            ["avatar_url"] ??
                                        "",
                                    placeholder: (context, url) => const Center(
                                      child: CupertinoActivityIndicator(
                                          color: AppTheme.textColor),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        GestureDetector(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.orange,
                                              Color.fromARGB(255, 255, 222, 59),
                                              Color.fromARGB(255, 225, 153, 47),
                                              Colors.red,
                                            ],
                                          ),
                                          color: Colors.orange,
                                        ),
                                        child: CircleAvatar(
                                          radius: 70,
                                          backgroundColor: Colors.transparent,
                                          child: Center(
                                            child: Text(
                                              data.user["user_metadata"]
                                                      ["full_name"]
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 64,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loading: () => const Center(
                                child: CupertinoActivityIndicator(
                                    color: AppTheme.textColor),
                              ),
                              error: (error, stack) => Container(
                                width: 70.0,
                                height: 70.0,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            data.user["user_metadata"]["full_name"],
                            style: headingTextStyle,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          onChanged: (value) {
                            nameController.text = value;
                          },
                          controller: nameController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: TextEditingController(
                            text: data.user["email"],
                          ),
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          style: const TextStyle(color: Colors.white),
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: Get.width,
                          child: GeneralButton(
                            hasPadding: true,
                            text: "Save",
                            color: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 4, 37, 6),
                            onPressed: () {
                              sessionData.updateUserName(nameController.text);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: Get.width,
                          child: GeneralButton(
                              hasPadding: true,
                              text: "Clear history",
                              color: Colors.white,
                              backgroundColor: Colors.grey.shade800,
                              onPressed: () {
                                Get.dialog(
                                  ConfirmDialog(
                                    heading: "Delete all history",
                                    subtitle:
                                        "Are you sure you want to delete all history?",
                                    confirmText: "Delete",
                                    onConfirm: () {
                                      ref.invalidate(historyProvider);
                                      Get.back();
                                      AllServices().deleteAllHistory(
                                        sessionState.value?.accessToken ?? "",
                                      );
                                    },
                                  ),
                                );
                              }),
                        ),
                        const SizedBox(
                            height: 80), // Add extra space at the bottom
                      ],
                    ),
                  ),
                  Container(
                    width: Get.width,
                    padding: const EdgeInsets.all(20),
                    child: GeneralButton(
                      hasPadding: true,
                      text: "Sign Out",
                      color: Colors.white,
                      backgroundColor: Colors.grey.shade800,
                      onPressed: () {
                        sessionData.logout();
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(
              child: SpinningSvg(
                svgWidget: Image.asset(
                  'assets/hdlogo.png',
                  height: 40,
                ),
                textList: const [
                  'Saving your data ...',
                  'Just a moment ...',
                  'Getting new data ...',
                  'Almost done ...',
                ],
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading user data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
