import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohey/core/data/ohey_last_account_store.dart';
import 'package:ohey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('last account store keeps the latest three unique accounts', () async {
    SharedPreferences.setMockInitialValues({});

    await OheyLastAccountStore.save(
      name: 'One',
      email: 'one@example.com',
      avatar: null,
    );
    await OheyLastAccountStore.save(
      name: 'Two',
      email: 'two@example.com',
      avatar: null,
    );
    await OheyLastAccountStore.save(
      name: 'Three',
      email: 'three@example.com',
      avatar: null,
    );
    await OheyLastAccountStore.save(
      name: 'Four',
      email: 'four@example.com',
      avatar: null,
    );

    var accounts = await OheyLastAccountStore.loadAccounts();
    expect(accounts.map((account) => account.email), [
      'four@example.com',
      'three@example.com',
      'two@example.com',
    ]);

    await OheyLastAccountStore.save(
      name: 'Two Updated',
      email: 'TWO@example.com',
      avatar: null,
    );

    accounts = await OheyLastAccountStore.loadAccounts();
    expect(accounts.map((account) => account.email), [
      'TWO@example.com',
      'four@example.com',
      'three@example.com',
    ]);
    expect(accounts.first.name, 'Two Updated');
  });
}
