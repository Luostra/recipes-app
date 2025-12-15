import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String? userEmail;
  final VoidCallback onSignOut;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBackToFolders;

  const AppDrawer({
    super.key,
    required this.userEmail,
    required this.onSignOut,
    this.title,
    this.subtitle,
    this.icon,
    this.onBackToFolders,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Заголовок Drawer
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon ?? Icons.restaurant_menu,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12, width: 400),
                Text(
                  title ?? 'RecipesApp',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Кнопка "Назад к папкам" если есть
          if (onBackToFolders != null) ...[
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Все папки'),
              onTap: () {
                Navigator.pop(context); // Закрываем Drawer
                onBackToFolders!();
              },
            ),
            const Divider(height: 1),
          ],

          // Информация о пользователе
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Аккаунт',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userEmail ?? 'Загрузка...',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Кнопка выхода
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Закрываем Drawer
              onSignOut();
            },
          ),

          const Spacer(),

          // Информация о версии приложения
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'RecipesApp v1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
