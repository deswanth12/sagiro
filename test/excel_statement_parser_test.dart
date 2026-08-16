import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/document_engine/parsers/excel/excel_statement_parser.dart';
import 'package:sagiro/models/transaction.dart';

void main() {
  group('ExcelStatementParser Multi-Format Tests', () {
    final parser = ExcelStatementParser();

    test('1. Parses Bank HTML Table disguised as .xls', () async {
      const htmlStatement = '''
      <!DOCTYPE html>
      <html>
      <head><title>SBI Account Statement</title></head>
      <body>
        <table border="1">
          <tr>
            <th>Txn Date</th>
            <th>Value Date</th>
            <th>Description</th>
            <th>Ref No/Cheque No</th>
            <th>Debit</th>
            <th>Credit</th>
            <th>Balance</th>
          </tr>
          <tr>
            <td>01/08/2026</td>
            <td>01/08/2026</td>
            <td>UPI/SWIGGY/421458963251/Order</td>
            <td>421458963251</td>
            <td>450.00</td>
            <td></td>
            <td>12,450.00</td>
          </tr>
          <tr>
            <td>05/08/2026</td>
            <td>05/08/2026</td>
            <td>SALARY CREDITED FOR JULY</td>
            <td>SAL0091</td>
            <td></td>
            <td>65,000.00</td>
            <td>77,450.00</td>
          </tr>
          <tr>
            <td>10/08/2026</td>
            <td>10/08/2026</td>
            <td>AMAZON PAY INDIA PVT LTD</td>
            <td>AMZ99201</td>
            <td>1,299.00</td>
            <td></td>
            <td>76,151.00</td>
          </tr>
        </table>
      </body>
      </html>
      ''';

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(htmlStatement)),
        fileName: 'SBI_Statement_Aug2026.xls',
        format: DocumentFormat.excel,
      );

      final result = await parser.parse(payload);
      expect(result.items.length, 3);

      final tx1 = result.items[0].transaction;
      expect(tx1.amount, 450.0);
      expect(tx1.type, TransactionType.debit);
      expect(tx1.date.day, 1);
      expect(tx1.date.month, 8);

      final tx2 = result.items[1].transaction;
      expect(tx2.amount, 65000.0);
      expect(tx2.type, TransactionType.credit);

      final tx3 = result.items[2].transaction;
      expect(tx3.amount, 1299.0);
      expect(tx3.type, TransactionType.debit);
    });

    test('2. Parses XML Spreadsheet 2003 .xls format', () async {
      const xmlStatement = '''<?xml version="1.0"?>
      <?mso-application progid="Excel.Sheet"?>
      <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
       xmlns:o="urn:schemas-microsoft-com:office:office"
       xmlns:x="urn:schemas-microsoft-com:office:excel"
       xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
       <Worksheet ss:Name="Sheet1">
        <Table>
         <Row>
          <Cell><Data ss:Type="String">Date</Data></Cell>
          <Cell><Data ss:Type="String">Narration</Data></Cell>
          <Cell><Data ss:Type="String">Withdrawal Amt</Data></Cell>
          <Cell><Data ss:Type="String">Deposit Amt</Data></Cell>
          <Cell><Data ss:Type="String">Closing Balance</Data></Cell>
         </Row>
         <Row>
          <Cell><Data ss:Type="String">12-Aug-2026</Data></Cell>
          <Cell><Data ss:Type="String">ZOMATO RESTAURANT</Data></Cell>
          <Cell><Data ss:Type="Number">380.00</Data></Cell>
          <Cell><Data ss:Type="String"></Data></Cell>
          <Cell><Data ss:Type="Number">24500.00</Data></Cell>
         </Row>
         <Row>
          <Cell><Data ss:Type="String">14-Aug-2026</Data></Cell>
          <Cell><Data ss:Type="String">REFUND FLIPKART</Data></Cell>
          <Cell><Data ss:Type="String"></Data></Cell>
          <Cell><Data ss:Type="Number">1200.00</Data></Cell>
          <Cell><Data ss:Type="Number">25700.00</Data></Cell>
         </Row>
        </Table>
       </Worksheet>
      </Workbook>
      ''';

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(xmlStatement)),
        fileName: 'HDFC_Statement.xls',
        format: DocumentFormat.excel,
      );

      final result = await parser.parse(payload);
      expect(result.items.length, 2);
      expect(result.items[0].transaction.amount, 380.0);
      expect(result.items[0].transaction.type, TransactionType.debit);
      expect(result.items[1].transaction.amount, 1200.0);
      expect(result.items[1].transaction.type, TransactionType.credit);
    });

    test('3. Parses Tab-Separated TSV renamed to .xls', () async {
      const tsvStatement =
          "Date\tParticulars\tDebit\tCredit\tBalance\n"
          "02/08/2026\tUBER TRIP MUMBAI\t520.00\t\t15000.00\n"
          "04/08/2026\tAIRTEL BROADBAND BILL\t999.00\t\t14001.00\n";

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(tsvStatement)),
        fileName: 'Bank_Statement.xls',
        format: DocumentFormat.excel,
      );

      final result = await parser.parse(payload);
      expect(result.items.length, 2);
      expect(result.items[0].transaction.amount, 520.0);
      expect(result.items[1].transaction.amount, 999.0);
    });
  });
}
