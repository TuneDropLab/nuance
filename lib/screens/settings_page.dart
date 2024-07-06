import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/widgets/general_button.dart';

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
    final focusNode = FocusNode();

    void editName() {
      // Navigate to a new screen to edit the user's name
      Get.to(() => EditNameScreen(sessionState: sessionState));
    }

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          key: lobalKey,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          drawerEnableOpenDragGesture: true,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium,
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

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: CachedNetworkImageProvider(
                              data.user["user_metadata"]["avatar_url"] ?? "",
                            ),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: editName,
                            child: Text(
                              data.user["user_metadata"]["full_name"],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: TextEditingController(
                            text: data.user["user_metadata"]["full_name"],
                          ),
                          decoration: InputDecoration(
                            labelText: 'Name',
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
                        TextField(
                          controller: TextEditingController(
                            text: data.user["email"],
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
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
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GeneralButton(
                        text: "Sign Out",
                        backgroundColor: Colors.red,
                        onPressed: () {
                          sessionData.logout();
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: AppTheme.textColor),
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

class EditNameScreen extends StatelessWidget {
  final AsyncValue<SessionData?> sessionState;
  const EditNameScreen({super.key, required this.sessionState});

  @override
  Widget build(BuildContext context) {
    final sessionData = sessionState.asData?.value?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(
                text: sessionData?["user_metadata"]["full_name"],
              ),
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              onSubmitted: (newName) {
                // Update the user's name in your backend or state management
                // ...
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
