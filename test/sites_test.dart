import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';

void main() {
  group('SiteModel tests', () {
    final sampleJson = {
      "items": [
        {
          "id": "b926c362-20f3-4ab2-a7f7-9c32d890439e",
          "name": "BPT",
          "code": "BPT_0001",
          "clientName": "BPT",
          "clientGroupId": "31601be4-8ef5-451a-bd45-dc9b53d02ab2",
          "clientEmail": "ravirokesh440@gmail.com",
          "contactPersonName": "Rokesh",
          "contactPhone": "8967120931",
          "location": null,
          "city": "NA",
          "state": "NA",
          "zoneId": "be542e12-7433-44d6-8246-c12b8c2aa401",
          "groupId": "cb89d03b-4788-4716-9521-70bb1d986e78",
          "clusterId": "cb89d03b-4788-4716-9521-70bb1d986e78",
          "billingPm": "740000.00",
          "clientType": "A",
          "contractAwardDate": "2026-11-02",
          "contractStartDate": "2026-10-30",
          "contractEndDate": "2026-11-01",
          "mode": "NEW",
          "plannedStartDate": "2026-11-02",
          "actualStartDate": "2026-11-02",
          "activationDate": "2026-11-02",
          "status": "LIVE",
          "primaryServiceId": "0b22fc91-5d94-437a-bb56-af84526b3b3e",
          "manpowerRequired": 32,
          "manpowerDeployed": 0,
          "machinery": [
            {
              "code": "MCH-03",
              "name": "High pressure jet",
              "masterId": "39e84a4b-8368-4a85-8f6d-da32eaab74d5",
              "quantity": 1,
              "frequency": "Bi-Monthly",
              "ppmApplicable": true
            }
          ],
          "specialAttention": false,
          "zone": "Hospitality",
          "zoneName": "Hospitality Zone",
          "cluster": "Pan India",
          "clusterName": "Pan India",
          "group": "Pan India",
          "groupName": "Pan India",
          "service": "HK",
          "serviceName": "HK",
          "lead": "Baskaran",
          "leadName": "Baskaran",
          "head": "Pandiyan",
          "headName": "Pandiyan",
          "shortage": 32,
          "ldStatus": "OPEN"
        },
        {
          "id": "dead9cff-9a84-4da6-879c-e8abd2627a3a",
          "name": "webtual",
          "code": "WEBTUA_8901",
          "clientName": "webtual",
          "billingPm": "4040000.00",
          "clientType": "A+",
          "status": "LIVE",
          "mode": "NEW",
          "primaryServiceId": "0b22fc91-5d94-437a-bb56-af84526b3b3e",
          "manpowerRequired": 32,
          "manpowerDeployed": 0,
          "shortage": 32,
          "special": true,
          "specialAttention": true,
          "zoneName": "Security Zone",
          "clusterName": "Security - KA",
          "service": "HK",
          "serviceName": "HK",
          "leadName": "Abhimanyu",
          "headName": "—"
        }
      ],
      "total": 6,
      "tabCounts": {
        "All": 6,
        "Draft": 0,
        "LIVE": 5,
        "Transition": 4,
        "Delayed": 0,
        "Special": 1
      }
    };

    test('parses sites response correctly', () {
      final response = SitesResponseModel.fromJson(sampleJson);
      expect(response.total, 6);
      expect(response.items.length, 2);
      expect(response.tabCounts.all, 6);
      expect(response.tabCounts.live, 5);
      expect(response.tabCounts.transition, 4);
      expect(response.tabCounts.special, 1);
      expect(response.tabCounts.draft, 0);
    });

    test('parses individual site model and formats billing correctly', () {
      final response = SitesResponseModel.fromJson(sampleJson);
      final bpt = response.items[0];

      expect(bpt.name, 'BPT');
      expect(bpt.code, 'BPT_0001');
      expect(bpt.clientType, 'A');
      expect(bpt.status, 'LIVE');
      expect(bpt.formattedBillingPm, '₹7.40L');
      expect(bpt.sublineDisplay, 'BPT_0001 · HK');
      expect(bpt.leadName, 'Baskaran');
      expect(bpt.specialAttention, false);
      expect(bpt.machinery.length, 1);
      expect(bpt.machinery[0].name, 'High pressure jet');

      final webtual = response.items[1];
      expect(webtual.name, 'webtual');
      expect(webtual.clientType, 'A+');
      expect(webtual.formattedBillingPm, '₹40.40L');
      expect(webtual.specialAttention, true);
      expect(webtual.leadName, 'Abhimanyu');
    });
  });
}

