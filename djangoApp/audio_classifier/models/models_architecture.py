import torch
import torch.nn as nn

class BiLSTMClassifier(nn.Module):
    def __init__(self, input_dim, hidden_dim=128, num_layers=1, dropout=0.3):

        super().__init__()
        self.bi_lstm1 = nn.LSTM(input_dim, hidden_dim, num_layers=num_layers, batch_first=True, bidirectional=True)
        self.dropout1 = nn.Dropout(dropout)
        self.bi_lstm2 = nn.LSTM(hidden_dim * 2, hidden_dim, num_layers=num_layers, batch_first=True, bidirectional=True)
        self.dropout2 = nn.Dropout(dropout)
        self.fc = nn.Linear(hidden_dim * 2, 2)

    def forward(self, x):

        out, _ = self.bi_lstm1(x)
        out = self.dropout1(out)
        out, _ = self.bi_lstm2(out)
        out = self.dropout2(out)
        out = out[:, -1, :]
        out = self.fc(out)
        return out



class ResidualBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride=1):

        super(ResidualBlock, self).__init__()
        self.stride = stride
        self.conv1 = nn.Conv2d(in_channels, out_channels, kernel_size=3, stride=1, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(out_channels)
        self.relu1 = nn.LeakyReLU(negative_slope=0.01)
        self.dropout = nn.Dropout2d(p=0.5)
        self.conv2 = nn.Conv2d(out_channels, out_channels, kernel_size=3, stride=stride, padding=1, bias=False)
        self.shortcut = nn.Sequential()

        if stride != 1 or in_channels != out_channels:
            self.shortcut = nn.Sequential(
                nn.Conv2d(in_channels, out_channels, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(out_channels))

        self.bn2 = nn.BatchNorm2d(out_channels)
        self.relu2 = nn.LeakyReLU(negative_slope=0.01)

    def forward(self, x):
        identity = x

        out = self.conv1(x)
        out = self.bn1(out)
        out = self.relu1(out)
        out = self.dropout(out)
        out = self.conv2(out)

        identity = self.shortcut(identity)

        out += identity
        out = self.bn2(out)
        out = self.relu2(out)
        return out


class AntiSpoofingResNet(nn.Module):
    def __init__(self, num_classes=2):
        super().__init__()

        self.initial_sequence = nn.Sequential(
            nn.Conv2d(in_channels=1, out_channels=32, kernel_size=3, stride=1, padding=1, bias=False),
            nn.BatchNorm2d(32),
            nn.LeakyReLU(negative_slope=0.01))
        self.residual_blocks = nn.Sequential(
            ResidualBlock(32, 32, stride=3),
            ResidualBlock(32, 32, stride=1),
            ResidualBlock(32, 32, stride=1),
            ResidualBlock(32, 32, stride=1),
            ResidualBlock(32, 32, stride=1),
            ResidualBlock(32, 32, stride=1))

        self.avg_pool = nn.AdaptiveAvgPool2d((1, 1))
        self.classifier = nn.Sequential(
            nn.Linear(32, 256),
            nn.Dropout(p=0.5),
            nn.LeakyReLU(negative_slope=0.01),
            nn.Linear(256, num_classes))

    def forward(self, x):
        out = self.initial_sequence(x)
        out = self.residual_blocks(out)
        out = self.avg_pool(out)
        out = torch.flatten(out, 1)
        out = self.classifier(out)

        return out