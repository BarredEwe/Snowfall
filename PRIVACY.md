# Privacy Policy for Snowfall

**Last updated:** December 08, 2025

## 1. Introduction
This Privacy Policy applies to the "Snowfall" macOS application (the "App"). The App is developed to provide aesthetic visual effects (snowfall) on your screen. We respect your privacy and are committed to protecting it.

## 2. Data Collection and Usage
**We do not collect, store, or transmit any personal data.**

The App operates entirely locally on your device. It does not require an internet connection to function, and it does not connect to any external servers.

## 3. Permissions and Technical Data
To provide the core functionality of the App (snowflakes melting on windows), the App requires specific local permissions:

*   **Window Interaction (Screen Recording / Accessibility):** The App analyzes the layout of open windows on your screen using standard macOS APIs (`CGWindowListCopyWindowInfo`).
    *   **Purpose:** This data is used solely to calculate physical interactions (collisions) between the snowflakes and your window borders.
    *   **Privacy:** This data is processed in real-time within the device's volatile memory (RAM). The App **does not** record screen contents, text, or images, and **does not** save or transmit this layout data anywhere.

*   **Local Settings:** The App saves your interface preferences (such as snow speed, size, and wind strength) locally on your device using standard macOS storage (`UserDefaults`).

## 4. Third-Party Services
The App does not use any third-party analytics, advertising frameworks, tracking SDKs, or cloud services. No user data is shared with third parties.

## 5. Contact Us
If you have any questions about this Privacy Policy, please contact us at:

**Email:** barredewe@gmail.com

---

# Политика конфиденциальности (Russian)

**Дата последнего обновления:** 8 декабря 2025 г.

## 1. Введение
Данная Политика конфиденциальности относится к приложению «Snowfall» для macOS. Мы уважаем вашу конфиденциальность: приложение создано исключительно для визуального оформления рабочего стола и не предназначено для сбора информации о пользователе.

## 2. Сбор и использование данных
**Мы не собираем, не храним и не передаем никакие персональные данные.**

Приложение работает полностью автономно на вашем устройстве. Оно не использует интернет-соединение для отправки каких-либо отчетов и не связывается со сторонними серверами.

## 3. Доступ к системным функциям
Для работы функции взаимодействия снега с окнами приложению требуются следующие технические разрешения:

*   **Анализ окон (Window Interaction):** Приложение получает координаты открытых окон через стандартные API macOS.
    *   **Цель:** Данные используются исключительно для математического расчета столкновений снежинок с границами окон (эффект таяния).
    *   **Конфиденциальность:** Эти данные обрабатываются в оперативной памяти в режиме реального времени. Приложение **не записывает** содержимое экрана, текст или изображения и **никогда** не передает эту информацию вовне.

*   **Локальные настройки:** Ваши предпочтения (скорость снега, размер, сила ветра) сохраняются только локально на вашем устройстве (в `UserDefaults`).

## 4. Сторонние сервисы
В приложении отсутствуют сторонние системы аналитики, трекеры или рекламные модули.

## 5. Контакты
Если у вас возникли вопросы касательно данной политики, вы можете связаться с нами по адресу:

**Email:** barredewe@gmail.com
