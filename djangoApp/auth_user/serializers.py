from rest_framework.validators import UniqueTogetherValidator, UniqueValidator
import re
from django.core.exceptions import ValidationError as DjangoValidationError
from django.contrib.auth.password_validation import validate_password as django_validate_password
from rest_framework import serializers
from django.contrib.auth.models import User
from rest_framework.validators import UniqueValidator

class UserSerializer(serializers.ModelSerializer):

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user

    class Meta:
        model = User
        fields = (
            'username',
            'first_name',
            'last_name',
            'email',
            'password',
        )
        validators = [
            UniqueTogetherValidator(
                queryset=User.objects.all(),
                fields=['username', 'email']
            )
        ]

class RegisterSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
        required=True,
        error_messages={
            "invalid": "Wprowadź poprawny adres e-mail.",
            "blank": "Pole email nie może być puste."
        },
        validators=[
            UniqueValidator(
                queryset=User.objects.all(),
                message="Użytkownik z takim adresem e-mail już istnieje."
            )
        ]
    )

    username = serializers.CharField(
        required=True,
        error_messages={
            "blank": "Nazwa użytkownika nie może być pusta."
        },
        validators=[
            UniqueValidator(
                queryset=User.objects.all(),
                message="Użytkownik o takiej nazwie już istnieje."
            )
        ]
    )

    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        error_messages={
            "blank": "Hasło nie może być puste."
        }
    )

    class Meta:
        model = User
        fields = ('username', 'email', 'password')

    def validate_password(self, value):
        """
        Ręcznie wywołujemy django_validate_password, łapiemy
        django.core.exceptions.ValidationError i tłumaczymy komunikaty.
        """
        try:
            # ręczne uruchomienie validatorów hasła Django
            django_validate_password(value)
        except DjangoValidationError as exc:
            translated = []

            # REGUŁY - dopasowania (używamy lower + regex/substring)
            rules = [
                (r"too short", "Hasło jest za krótkie — musi mieć co najmniej 8 znaków."),
                (r"must contain at least", "Hasło jest za krótkie — musi mieć co najmniej 8 znaków."),
                (r"too common", "Hasło jest zbyt popularne."),
                (r"commonly used", "Hasło jest zbyt popularne."),
                (r"common password", "Hasło jest zbyt popularne."),
                (r"entirely numeric", "Hasło nie może składać się wyłącznie z cyfr."),
                (r"entirely numeric", "Hasło nie może składać się wyłącznie z cyfr."),
                (r"similar", "Hasło jest zbyt podobne do danych konta."),
                (r"too similar", "Hasło jest zbyt podobne do danych konta."),
            ]

            for msg in exc.messages:
                msg_lower = str(msg).lower()
                matched = False

                for pattern, translation in rules:
                    if re.search(pattern, msg_lower):
                        translated.append(translation)
                        matched = True
                        break

                if not matched:
                    # Jeśli nie dopasowano, dorzuć oryginalny komunikat (bez opakowania)
                    # lub ogólny komunikat, jeśli wolisz ukryć angielski tekst:
                    # translated.append("Niepoprawne hasło.")
                    translated.append(str(msg))

            raise serializers.ValidationError(translated)

        return value

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)
    confirm_password = serializers.CharField(required=True)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError(
                {"confirm_password": ["Nowe hasła nie są identyczne."]}
            )
        return data

    def validate_password(self, value):
        """
        Ręcznie wywołujemy django_validate_password, łapiemy
        django.core.exceptions.ValidationError i tłumaczymy komunikaty.
        """
        try:
            # ręczne uruchomienie validatorów hasła Django
            django_validate_password(value)
        except DjangoValidationError as exc:
            translated = []

            # REGUŁY - dopasowania (używamy lower + regex/substring)
            rules = [
                (r"too short", "Hasło jest za krótkie — musi mieć co najmniej 8 znaków."),
                (r"must contain at least", "Hasło jest za krótkie — musi mieć co najmniej 8 znaków."),
                (r"too common", "Hasło jest zbyt popularne."),
                (r"commonly used", "Hasło jest zbyt popularne."),
                (r"common password", "Hasło jest zbyt popularne."),
                (r"entirely numeric", "Hasło nie może składać się wyłącznie z cyfr."),
                (r"entirely numeric", "Hasło nie może składać się wyłącznie z cyfr."),
                (r"similar", "Hasło jest zbyt podobne do danych konta."),
                (r"too similar", "Hasło jest zbyt podobne do danych konta."),
            ]

            for msg in exc.messages:
                msg_lower = str(msg).lower()
                matched = False

                for pattern, translation in rules:
                    if re.search(pattern, msg_lower):
                        translated.append(translation)
                        matched = True
                        break

                if not matched:
                    # Jeśli nie dopasowano, dorzuć oryginalny komunikat (bez opakowania)
                    # lub ogólny komunikat, jeśli wolisz ukryć angielski tekst:
                    # translated.append("Niepoprawne hasło.")
                    translated.append(str(msg))

            raise serializers.ValidationError(translated)

    def validate_new_password(self, value):
        try:
            self.validate_password(value)
        except DjangoValidationError as exc:

            translated = []
            rules = [
                ("too short", "Hasło jest za krótkie — minimum 8 znaków."),
                ("too common", "Hasło jest zbyt popularne."),
                ("entirely numeric", "Hasło nie może być tylko z cyfr."),
                ("similar", "Hasło jest zbyt podobne do danych konta."),
            ]

            for msg in exc.messages:
                msg_lower = msg.lower()
                matched = False

                for key, translation in rules:
                    if key in msg_lower:
                        translated.append(translation)
                        matched = True
                        break

                if not matched:
                    translated.append("Hasło nie spełnia wymagań bezpieczeństwa.")

            raise serializers.ValidationError(translated)

        return value

