import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';

class AdaptiveTable extends StatelessWidget {
  const AdaptiveTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });
  final List<String> headers;
  final List<List<String>> rows;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    if (!context.isExpanded) {
      return ListView.separated(
        padding: padding,
        itemCount: rows.length,
        itemBuilder: itemBuilder,
        separatorBuilder: (_, _) => const Divider(height: 1),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final header in [...headers, 'Detalhes']) DataColumn(label: Text(header)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                cells: [
                  for (final text in rows[i])
                    DataCell(SizedBox(width: 150, child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis))),
                  DataCell(
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => Dialog(
                          child: SizedBox(
                            width: 560,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    tooltip: 'Fechar',
                                    onPressed: () => Navigator.pop(dialogContext),
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                                Flexible(child: SingleChildScrollView(child: itemBuilder(context, i))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Ver detalhes'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
