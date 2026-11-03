import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/governance_matrix/data/models/governance_matrix_model.dart';

void main() {
  group('GovernanceMatrixModel tests', () {
    final sampleJson = {
      'items': [
        {
          'id': '75d5be8d-b41c-40fc-9699-01a91d175a33',
          'tabKey': 'crrm',
          'tabName': 'CRRM',
          'clientType': 'A+',
          'billingPm': 'Above ₹10L',
          'frequencies': {'frequency': 'Quarterly'},
          'columnsConfig': [
            {'key': 'frequency', 'label': 'Frequency'}
          ],
          'sortOrder': 1,
          'active': true,
        },
        {
          'id': '351b0939-5f60-482f-8de3-29218eb2db3d',
          'tabKey': 'ld_training',
          'tabName': 'Transition Training',
          'clientType': 'A+',
          'billingPm': 'Above ₹10L',
          'frequencies': {'frequency': 'Monthly Once / Twice'},
          'columnsConfig': [
            {'key': 'frequency', 'label': 'Frequency'}
          ],
          'sortOrder': 1,
          'active': true,
        },
        {
          'id': '42a49644-bde7-4117-814e-99547ecde49c',
          'tabKey': 'operations',
          'tabName': 'Operations',
          'clientType': 'A+',
          'billingPm': 'Above ₹10L',
          'frequencies': {
            'rr': 'N/A',
            'coo': 'QBR',
            'mis': 'In Person - Cluster Head',
            'mmr': 'Monthly',
            'zonalHead': 'Bi-Monthly',
            'clusterHead': 'Monthly',
            'clusterLead': 'Every 15 Days',
            'fieldExecutive': 'Weekly',
            'clusterExecutive': 'Weekly',
            'groupClusterHead': 'Bi-Monthly'
          },
          'columnsConfig': [
            {'key': 'fieldExecutive', 'label': 'Field Executive'},
            {'key': 'clusterExecutive', 'label': 'Cluster Executive'},
            {'key': 'clusterLead', 'label': 'Cluster Lead'},
            {'key': 'clusterHead', 'label': 'Cluster Head'},
            {'key': 'groupClusterHead', 'label': 'Group Cluster Head'},
            {'key': 'zonalHead', 'label': 'Zonal Head'},
            {'key': 'coo', 'label': 'COO'},
            {'key': 'mmr', 'label': 'MMR'},
            {'key': 'mis', 'label': 'MIS'},
            {'key': 'rr', 'label': 'R&R'}
          ],
          'sortOrder': 1,
          'active': true,
        },
        {
          'id': '607ab0a7-e3d9-4e03-9aad-63672e75ed4c',
          'tabKey': 'operations',
          'tabName': 'Operations',
          'clientType': 'A',
          'billingPm': '₹5L - ₹10L',
          'frequencies': {
            'rr': 'N/A',
            'coo': 'Half-Yearly',
            'mis': 'In Person - Cluster Lead',
            'mmr': 'Monthly',
            'zonalHead': 'QBR',
            'clusterHead': 'Bi-Monthly',
            'clusterLead': 'Monthly',
            'fieldExecutive': 'Weekly',
            'clusterExecutive': 'Every 15 Days',
            'groupClusterHead': 'Bi-Monthly'
          },
          'columnsConfig': [],
          'sortOrder': 2,
          'active': true,
        }
      ]
    };

    test('parses governance matrix items and unique tabs correctly', () {
      final res = GovernanceMatrixResponseModel.fromJson(sampleJson);
      expect(res.items.length, 4);

      final tabs = res.uniqueTabs;
      expect(tabs.length, 3);
      // Canonical ordering puts operations first, then ld_training, then crrm
      expect(tabs[0].key, 'operations');
      expect(tabs[0].name, 'Operations');
      expect(tabs[1].key, 'ld_training');
      expect(tabs[1].name, 'L & D');
      expect(tabs[2].key, 'crrm');
      expect(tabs[2].name, 'CRRM');
    });

    test('retrieves items and columns config for tab correctly', () {
      final res = GovernanceMatrixResponseModel.fromJson(sampleJson);

      final opsItems = res.getItemsForTab('operations');
      expect(opsItems.length, 2);
      expect(opsItems[0].clientType, 'A+');
      expect(opsItems[0].billingPm, 'Above ₹10L');
      expect(opsItems[0].frequencies['fieldExecutive'], 'Weekly');
      expect(opsItems[1].clientType, 'A');
      expect(opsItems[1].frequencies['coo'], 'Half-Yearly');

      final cols = res.getColumnsConfigForTab('operations');
      expect(cols.length, 10);
      expect(cols.first.label, 'Field Executive');
      expect(cols.last.label, 'R&R');
    });

    test('parses single frequency tab correctly', () {
      final res = GovernanceMatrixResponseModel.fromJson(sampleJson);

      final crrmItems = res.getItemsForTab('crrm');
      expect(crrmItems.length, 1);
      expect(crrmItems.first.frequencies['frequency'], 'Quarterly');

      final ldItems = res.getItemsForTab('ld_training');
      expect(ldItems.length, 1);
      expect(ldItems.first.displayTabName, 'L & D');
      expect(ldItems.first.frequencies['frequency'], 'Monthly Once / Twice');
    });
  });
}

