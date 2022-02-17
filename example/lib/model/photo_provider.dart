import 'package:flutter/foundation.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import '../main.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = <AssetPathEntity>[];

  RequestType type = RequestType.common;

  bool hasAll = true;

  bool onlyAll = false;

  bool _notifying = false;

  bool _needTitle = false;

  bool get needTitle => _needTitle;

  set needTitle(bool? needTitle) {
    if (needTitle == null) {
      return;
    }
    _needTitle = needTitle;
    notifyListeners();
  }

  bool _containsEmptyAlbum = false;

  bool get containsEmptyAlbum => _containsEmptyAlbum;

  set containsEmptyAlbum(bool containsEmptyAlbum) {
    _containsEmptyAlbum = containsEmptyAlbum;
    notifyListeners();
  }

  bool _containsPathModified = false;

  bool get containsPathModified => _containsPathModified;

  set containsPathModified(bool containsPathModified) {
    _containsPathModified = containsPathModified;
    notifyListeners();
  }

  bool _containsLivePhotos = true;

  bool get containsLivePhotos => _containsLivePhotos;

  set containsLivePhotos(bool value) {
    _containsLivePhotos = value;
    notifyListeners();
  }

  bool _onlyLivePhotos = false;

  bool get onlyLivePhotos => _onlyLivePhotos;

  set onlyLivePhotos(bool value) {
    _onlyLivePhotos = value;
    notifyListeners();
  }

  DateTime _startDt = DateTime(2005); // Default Before 8 years

  DateTime get startDt => _startDt;

  set startDt(DateTime startDt) {
    _startDt = startDt;
    notifyListeners();
  }

  DateTime _endDt = DateTime.now();

  DateTime get endDt => _endDt;

  set endDt(DateTime endDt) {
    _endDt = endDt;
    notifyListeners();
  }

  bool _asc = false;

  bool get asc => _asc;

  set asc(bool? asc) {
    if (asc == null) {
      return;
    }
    _asc = asc;
    notifyListeners();
  }

  ThumbnailFormat _thumbFormat = ThumbnailFormat.jpeg;

  ThumbnailFormat get thumbFormat => _thumbFormat;

  set thumbFormat(ThumbnailFormat thumbFormat) {
    _thumbFormat = thumbFormat;
    notifyListeners();
  }

  bool get notifying => _notifying;

  String minWidth = '0';
  String maxWidth = '10000';
  String minHeight = '0';
  String maxHeight = '10000';
  bool _ignoreSize = true;

  bool get ignoreSize => _ignoreSize;

  set ignoreSize(bool? ignoreSize) {
    if (ignoreSize == null) {
      return;
    }
    _ignoreSize = ignoreSize;
    notifyListeners();
  }

  Duration _minDuration = Duration.zero;

  Duration get minDuration => _minDuration;

  set minDuration(Duration minDuration) {
    _minDuration = minDuration;
    notifyListeners();
  }

  Duration _maxDuration = const Duration(hours: 1);

  Duration get maxDuration => _maxDuration;

  set maxDuration(Duration maxDuration) {
    _maxDuration = maxDuration;
    notifyListeners();
  }

  set notifying(bool? notifying) {
    if (notifying == null) {
      return;
    }
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(RequestType type) {
    this.type = type;
    notifyListeners();
  }

  void changeHasAll(bool? value) {
    if (value == null) {
      return;
    }
    hasAll = value;
    notifyListeners();
  }

  void changeOnlyAll(bool? value) {
    if (value == null) {
      return;
    }
    onlyAll = value;
    notifyListeners();
  }

  void changeContainsEmptyAlbum(bool? value) {
    if (value == null) {
      return;
    }
    containsEmptyAlbum = value;
    notifyListeners();
  }

  void changeContainsPathModified(bool? value) {
    if (value == null) {
      return;
    }
    containsPathModified = value;
  }

  void reset() {
    list.clear();
  }

  Future<void> refreshGalleryList() async {
    final FilterOptionGroup option = makeOption();

    reset();
    final List<AssetPathEntity> galleryList =
        await PhotoManager.getAssetPathList(
      type: type,
      hasAll: hasAll,
      onlyAll: onlyAll,
      filterOption: option,
    );

    galleryList.sort((AssetPathEntity s1, AssetPathEntity s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    list.clear();
    list.addAll(galleryList);
  }

  FilterOptionGroup makeOption() {
    final FilterOption option = FilterOption(
      sizeConstraint: SizeConstraint(
        minWidth: int.tryParse(minWidth) ?? 0,
        maxWidth: int.tryParse(maxWidth) ?? 100000,
        minHeight: int.tryParse(minHeight) ?? 0,
        maxHeight: int.tryParse(maxHeight) ?? 100000,
        ignoreSize: ignoreSize,
      ),
      durationConstraint: DurationConstraint(
        min: minDuration,
        max: maxDuration,
      ),
      needTitle: needTitle,
    );

    final DateTimeCond createDtCond = DateTimeCond(
      min: startDt,
      max: endDt,
    );

    return FilterOptionGroup()
      ..setOption(AssetType.video, option)
      ..setOption(AssetType.image, option)
      ..setOption(AssetType.audio, option)
      ..createTimeCond = createDtCond
      ..containsEmptyAlbum = _containsEmptyAlbum
      ..containsPathModified = _containsPathModified
      ..containsLivePhotos = _containsLivePhotos
      ..onlyLivePhotos = onlyLivePhotos;
  }

  Future<void> refreshAllGalleryProperties() async {
    await Future.wait(
      List<Future<void>>.generate(list.length, (int i) async {
        final AssetPathEntity gallery = list[i];
        final AssetPathEntity newGallery =
            await AssetPathEntity.obtainPathFromProperties(
          id: gallery.id,
          albumType: gallery.albumType,
          type: gallery.type,
          optionGroup: gallery.filterOption,
        );
        list[i] = newGallery;
      }),
    );
    notifyListeners();
  }

  void changeThumbFormat() {
    if (thumbFormat == ThumbnailFormat.jpeg) {
      thumbFormat = ThumbnailFormat.png;
    } else {
      thumbFormat = ThumbnailFormat.jpeg;
    }
  }
}

class AssetPathProvider extends ChangeNotifier {
  AssetPathProvider(this.path) {
    onRefresh();
  }

  static const int loadCount = 50;

  bool isInit = false;

  AssetPathEntity path;

  List<AssetEntity> list = <AssetEntity>[];

  int page = 0;

  int get showItemCount {
    if (list.length == path.assetCount) {
      return path.assetCount;
    } else {
      return path.assetCount;
    }
  }

  bool refreshing = false;

  Future<void> onRefresh() async {
    if (refreshing) {
      return;
    }

    refreshing = true;
    path = await path.obtainForNewProperties(maxDateTimeToNow: false);
    final List<AssetEntity> list = await path.getAssetListPaged(
      page: 0,
      size: loadCount,
    );
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength('onRefresh');

    refreshing = false;
  }

  Future<void> onLoadMore() async {
    if (refreshing) {
      return;
    }
    if (showItemCount > path.assetCount) {
      print('already max');
      return;
    }
    final List<AssetEntity> list = await path.getAssetListPaged(
      page: page + 1,
      size: loadCount,
    );
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
    printListLength('loadmore');
  }

  Future<void> delete(AssetEntity entity) async {
    final List<String> result = await PhotoManager.editor.deleteWithIds(
      <String>[entity.id],
    );
    if (result.isNotEmpty) {
      final int rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final List<AssetEntity> list = await path.getAssetListRange(
        start: 0,
        end: rangeEnd,
      );
      this.list.clear();
      this.list.addAll(list);
      printListLength('deleted');
    }
  }

  Future<void> deleteSelectedAssets(List<AssetEntity> entity) async {
    final List<String> ids = entity.map((AssetEntity e) => e.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
    path = await path.obtainForNewProperties();
    showToast('The path ${path.name} asset count have :${path.assetCount}');
    notifyListeners();
  }

  Future<void> removeInAlbum(AssetEntity entity) async {
    if (await PhotoManager.editor.iOS.removeInAlbum(entity, path)) {
      final int rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final List<AssetEntity> list = await path.getAssetListRange(
        start: 0,
        end: rangeEnd,
      );
      this.list.clear();
      this.list.addAll(list);
      printListLength('removeInAlbum');
    }
  }

  void printListLength(String tag) {
    print('$tag length : ${list.length}');
  }
}
