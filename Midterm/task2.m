clear
close all
% Task a)
f = 107000;
fs = 1000000;
N = 10000;
% Form even indexed samples
y0=zeros(1,N*2);
y0(1:2:end) = cos(2*pi*[0:N-1]*f/fs);
% Form odd indexed samples
y1=zeros(1,N*2);
y1(2:2:end)=cos(2*pi*[0.5:N-0.5]*f/fs);
% Form interleaved samples
y01=y0+y1;

% Plot time series of ADC samples
figure
subplot(3,1,1)
stem(y0(1:50))
title('Time series of even indexed samples')
ylim([-1 1])
subplot(3,1,2)
stem(y1(1:50))
title('Time series of odd indexed samples')
ylim([-1 1])
subplot(3,1,3)
stem(linspace(1,50,100),y01(1:100))
title('Time series of interleaved samples')
ylim([-1 1])

% % Plot spectrum of ADC samples
figure
subplot(3,1,1)
ww = kaiser(20000)';
ww = ww/sum(ww);

plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y0).*ww))))
title('Spectrum of even indexed samples')
ylim([1-100 0])
subplot(3,1,2)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y1).*ww))))
title('Spectrum of odd indexed samples')
ylim([-100 0])
subplot(3,1,3)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y01).*ww))))
title('Spectrum of interleaved samples')
ylim([-100 0])
xlim([-1e6 1e6])

% Task b)
g0=1;
g1=1.05;
dc0=-0.06;
dc1=0.05;

% Apply gain imbalance and DC offset to even samples
y0g=zeros(1,20000);
y0g(1:2:end) = g0*y0(1:2:end)+dc0;
% Apply gain imbalance and DC offset to odd samples
y1g=zeros(1,20000);
y1g(2:2:end) = g1*y1(2:2:end)+dc1;
% Interleave odd and even samples
y01g=y0g+y1g;

% Plot time series of distorted ADC samples
figure
subplot(3,1,1)
stem(y0g(1:50))
title('Time series of even indexed samples with DC offset and gain imbalance')
ylim([-1.5 1.5])
subplot(3,1,2)
stem(y1g(1:50))
title('Time series of odd indexed samples with DC offset and gain imbalance')
ylim([-1.5 1.5])
subplot(3,1,3)
stem(y01g(1:100))
title('Time series of interleaved samples with DC offset and gain imbalance')
ylim([-1.5 1.5])

figure
subplot(3,1,1)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y0g).*ww))))
title('Spectrum of even indexed samples with DC offset and gain imbalance')
ylim([-100 0])
subplot(3,1,2)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y1g).*ww))))
title('Spectrum of odd indexed samples with DC offset and gain imbalance')
ylim([-100 0])
subplot(3,1,3)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y01g).*ww))))
title('Spectrum of interleaved samples with DC offset and gain imbalance')
ylim([-100 0])

% Task c)

% Cancel DC of even samples
y0c=zeros(1,N*2);
[y0c(1:2:N*2), dc_hat_0]=DC_canceller(y0g(1:2:N*2),N,0.01);

% Cancel DC of odd samples
y1c=zeros(1,N*2);
[y1c(2:2:N*2), dc_hat_1]=DC_canceller(y1g(2:2:N*2),N,0.01);

% Interleave DC-cancelled samples
x0=y0c+y1c;

% Plot DC estimates
figure
subplot(2,1,1)
plot(0:999,dc_hat_0(1:1000))
title('DC estimates for even samples')
hold on
plot([0 999],[-0.06 -0.06],'r')
subplot(2,1,2)
plot(0:999,dc_hat_1(1:1000))
hold on
plot([0 999],[0.05 0.05])
title('DC estimates for odd samples')

% Plot spectrum of DC cancelled signal
ww2=kaiser(N,10)';
ww2=ww2/sum(ww2);
figure
subplot(3,1,1)
plot(linspace(-0.5,0.5,N)*fs*2,fftshift(20*log10(abs(fft(y0c(10001:end)).*ww2))))
title('Spectrum of even indexed samples with DC cancelled')
ylim([-100 0])
subplot(3,1,2)
plot(linspace(-0.5,0.5,N)*fs*2,fftshift(20*log10(abs(fft(y1c(10001:end)).*ww2))))
title('Spectrum of odd indexed samples with DC cancelled')
ylim([-100 0])
subplot(3,1,3)
plot(linspace(-0.5,0.5,N)*fs*2,fftshift(20*log10(abs(fft(x0(10001:end)).*ww2))))
title('Spectrum of interleaved samples with DC cancelled')
ylim([-100 0])

%Task d)

Fpass = 800000;
Fstop = 750000;
Ap = 1;
Ast = 100;
fs = 2000000;

% Generate filter

d = designfilt('highpassfir','PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'PassbandRipple',Ap,'StopbandAttenuation',...
  Ast, 'SampleRate', fs);

h = tf(d);

cg_new=1;

% Balance gain 
reg0=zeros(1,135);
reg1=zeros(1,135);
y4_sv=zeros(1,N*2);
x3=zeros(1,N*2);
mu=0.01;

for nn = 1:N*2
    cg=cg_new;
    x1=x0(nn)*cos(pi*nn);
    x2=cg*x1;
    x3(nn)=x0(nn)-x2;
    reg0=[x0(nn) reg0(1:134)];
    reg1=[x1 reg1(1:134)];
    y1=reg1*h';
    y2=y1*cg;
    y3=reg0*h';
    y4=y3-y2;
    y4_sv(nn)=y4;
    cg=y4*mu+cg;
end

% Plot spectrum of signal presented to the LMS canceller
figure
subplot(3,1,1)
plot(linspace(-0.5,0.5,N)*fs*2,fftshift(20*log10(abs(fft(x0(10001:end)).*ww2))))
title('Spectrum of signals presented to the LMS canceller')
ylim([-100 0])
subplot(3,1,2)
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(y4_sv).*ww))))
title('Spectrum of error signal')
subplot(3,1,3)
plot(0:999,y4_sv(1:1000))

title('Canceller learning curve')

figure
plot(linspace(-0.5,0.5,N*2)*fs*2,fftshift(20*log10(abs(fft(x3).*ww))))
title('Spectrum of gain cancelled signal')
ylim([-100 0])



