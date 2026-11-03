import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/mom/data/models/mom_activity_model.dart';

void main() {
  group('MomActivityModel tests', () {
    test('parses pending mom activity correctly', () {
      final json = {
        'id': '13614e90-2386-439f-9eca-29f380013799',
        'siteId': '2916aba6-a14d-4287-8771-0a496f10fd87',
        'siteName': 'Digi-demo2',
        'role': 'ZONAL_HEAD',
        'roleLabel': 'Zonal Head',
        'kind': 'GOVERNANCE',
        'title': 'Zonal Head Visit',
        'code': 'ACT-13614',
        'scheduledDate': '2026-10-30',
        'dueDate': '2026-10-30',
        'visitDate': '2026-10-30',
        'status': 'COMPLETED',
        'statusLabel': 'Pending',
        'mom': {},
      };

      final activity = MomActivityModel.fromJson(json);
      expect(activity.id, '13614e90-2386-439f-9eca-29f380013799');
      expect(activity.title, 'Zonal Head Visit');
      expect(activity.code, 'ACT-13614');
      expect(activity.isPending, isTrue);
      expect(activity.isSent, isFalse);
      expect(activity.formattedVisitDate, '30 Oct 2026');
      expect(activity.generateDefaultSubject('Digi-demo2'),
          'Site walkaround MOM — Digi-demo2 — 30 Oct 2026');
    });

    test('parses completed mom activity correctly', () {
      final json = {
        'id': 'dd5bf639-ca53-456d-85c4-f72027e505b1',
        'siteId': '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        'siteName': 'Space Intel',
        'role': 'CLUSTER_EXECUTIVE',
        'roleLabel': 'Cluster Executive',
        'kind': 'GOVERNANCE',
        'title': 'Cluster Executive Visit',
        'code': 'ACT-2A0B8',
        'scheduledDate': '2026-10-22',
        'dueDate': '2026-10-22',
        'visitDate': '2026-10-22',
        'status': 'COMPLETED',
        'statusLabel': 'Sent',
        'mom': {
          'to': ['prathap.p@digilogy.co'],
          'cc': ['m.karthikeyan@casagrand.co.in'],
          'subject': 'Site walkaround MOM — Space Intel — 30 Oct 2026',
          'points': [
            {
              'point': 'Ceiling Lights Free From Dust & Cobwebs — test',
              'targetDate': '2026-10-30',
            },
            {
              'point': 'food delay',
              'targetDate': '2026-10-31',
            }
          ],
          'closing': 'Next governance visit will follow the scheduled frequency.',
          'sentAt': '2026-10-30T05:38:53.908Z',
        },
      };

      final activity = MomActivityModel.fromJson(json);
      expect(activity.id, 'dd5bf639-ca53-456d-85c4-f72027e505b1');
      expect(activity.title, 'Cluster Executive Visit');
      expect(activity.isSent, isTrue);
      expect(activity.isPending, isFalse);
      expect(activity.mom.to.first, 'prathap.p@digilogy.co');
      expect(activity.mom.cc.first, 'm.karthikeyan@casagrand.co.in');
      expect(activity.mom.points.length, 2);
      expect(activity.mom.points[0].formattedTargetDate(includeWeekday: false),
          '30 Oct 2026');
    });
  });
}

