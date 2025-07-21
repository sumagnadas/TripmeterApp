import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmeter/app_state.dart';

/// Flutter code sample for [SimpleCascadingMenuApp].

/// A Simple Cascading Menu example using the [MenuAnchor] Widget.
class MyCascadingMenu extends StatefulWidget {
  const MyCascadingMenu({super.key});

  @override
  State<MyCascadingMenu> createState() => _MyCascadingMenuState();
}

class _MyCascadingMenuState extends State<MyCascadingMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            unawaited(appState.initializeNTP());
          },
          child: Text(
            'NTP Reset',
            style: theme.textTheme.displaySmall!.copyWith(fontSize: 30),
          ),
        ),
        // MenuItemButton(onPressed: () {}, child: const Text('Setting')),
        // MenuItemButton(onPressed: () {}, child: const Text('Send Feedback')),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          focusNode: _buttonFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.menu),
        );
      },
    );
  }
}
