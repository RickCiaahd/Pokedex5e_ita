// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../repositories/tm_repository.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

part 'bag_screen_controller.dart';
part 'bag_screen_actions.dart';
part 'bag_screen_item_use.dart';
part 'bag_screen_helpers.dart';
part 'bag_screen_models.dart';
part 'bag_screen_content.dart';
part 'bag_screen_item_widgets.dart';
part 'bag_screen_picker_widgets.dart';
part 'bag_screen_item_picker_sheet.dart';
part 'bag_screen_sell_sheet.dart';
part 'bag_screen_support.dart';
