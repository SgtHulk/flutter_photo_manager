import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'order_by_action.dart';

class CustomFilterSqlPage extends StatefulWidget {
  const CustomFilterSqlPage({Key? key}) : super(key: key);

  @override
  State<CustomFilterSqlPage> createState() => _CustomFilterSqlPageState();
}

class _CustomFilterSqlPageState extends State<CustomFilterSqlPage> {
  List<AssetPathEntity> _list = [];

  final TextEditingController _whereController = TextEditingController();
  final List<OrderByItem> _orderBy = [];

  @override
  void initState() {
    super.initState();
    _whereController.text = 'width >= 1000';
    _refresh();
  }

  @override
  void dispose() {
    _whereController.dispose();
    super.dispose();
  }

  BaseFilter createCustomFilter() {
    final filter = CustomFilter.sql(
      where: _whereController.text,
      orderBy: _orderBy,
    );
    return filter;
  }

  Future<void> _refresh() async {
    final List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
      filterOption: createCustomFilter(),
    );
    setState(() {
      _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Filter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          OrderByAction(
            items: _orderBy,
            onChanged: (List<OrderByItem> value) {
              setState(() {
                _orderBy.clear();
                _orderBy.addAll(value);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _whereController,
            decoration: const InputDecoration(
              labelText: 'Where',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                final AssetPathEntity path = _list[index];
                return ListTile(
                  title: Text(path.name),
                  subtitle: Text(path.id),
                  trailing: FutureBuilder<int>(
                    future: path.assetCountAsync,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data.toString());
                      }
                      return const SizedBox();
                    },
                  ),
                  onTap: () async {
                    final count = await path.assetCountAsync;
                    showToast(
                      'Asset count: $count',
                      position: ToastPosition.bottom,
                    );
                  },
                );
              },
              itemCount: _list.length,
            ),
          ),
        ],
      ),
    );
  }
}
