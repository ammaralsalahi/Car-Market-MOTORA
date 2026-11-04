
import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
class InquiriesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب استفسارات العميل مع بيانات السيارات والمعارض.
  Future<List<Map<String, dynamic>>> getMyInquiries() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return [];

    final response = await _supabase
        .from('inquiries')
        .select('id, user_id, car_id, message, status, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final inquiries = List<Map<String, dynamic>>.from(response);

    if (inquiries.isEmpty) return [];

    final carIds = inquiries
        .map((item) => item['car_id'].toString())
        .toSet()
        .toList();

    final carsResponse = await _supabase
        .from('cars')
        .select('''
          id,
          title,
          year,
          price,
          dealership_id,
          brands!cars_brand_id_fkey(name),
          models!cars_model_brand_fk(name),
          dealerships!cars_dealership_id_fkey(name),
          car_images(image_url, display_order)
        ''')
        .inFilter('id', carIds);

    final cars = List<Map<String, dynamic>>.from(carsResponse);

    final carsMap = {
      for (final car in cars) car['id'].toString(): car,
    };

    return inquiries.map((inquiry) {
      return {
        ...inquiry,
        'car': carsMap[inquiry['car_id'].toString()],
      };
    }).toList();
  }

  /// جلب رسائل محادثة محددة.
  Future<List<Map<String, dynamic>>> getMessages(
    String inquiryId,
  ) async {
    final response = await _supabase
        .from('inquiry_messages')
        .select('''
          id,
          inquiry_id,
          sender_id,
          message,
          created_at,
          read_at
        ''')
        .eq('inquiry_id', inquiryId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// إرسال رسالة جديدة.
  Future<void> sendMessage({
    required String inquiryId,
    required String message,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You must sign in to send messages.');
    }

    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) return;

    await _supabase.from('inquiry_messages').insert({
      'inquiry_id': inquiryId,
      'sender_id': user.id,
      'message': cleanMessage,
    });
  }

  /// الاستماع للرسائل الجديدة في محادثة معينة.
  RealtimeChannel subscribeToMessages({
    required String inquiryId,
    required VoidCallback onNewMessage,
  }) {
    final channel = _supabase.channel('inquiry-chat-$inquiryId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'inquiry_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'inquiry_id',
            value: inquiryId,
          ),
          callback: (payload) {
            onNewMessage();
          },
        )
        .subscribe();

    return channel;
  }

  /// إيقاف الاستماع للمحادثة.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
