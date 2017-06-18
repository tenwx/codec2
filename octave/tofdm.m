% tofdm.m
% David Rowe and Steve Sampson June 2017
%
% Octave script for comparing Octave and C versions of OFDZM modem


Nframes = 3;

more off; format;
ofdm_lib;
autotest;

% ---------------------------------------------------------------------
% Run Octave version 
% ---------------------------------------------------------------------

Ts = 0.018; Tcp = 0.002; Rs = 1/Ts; bps = 2; Nc = 16; Ns = 8;
states = ofdm_init(bps, Rs, Tcp, Ns, Nc);
ofdm_load_const;

rand('seed',1);
tx_bits = round(rand(1,Nbitsperframe));

% Run tx loop

tx_bits_log = []; tx_log = [];
for f=1:Nframes
  tx_bits_log = [tx_bits_log tx_bits];
  tx_log = [tx_log ofdm_mod(states, tx_bits)];
end

% Channel simulation

rx = tx_log;

% Init rx with ideal timing so we can test with timing estimation disabled

Nsam = length(rx);
prx = 1;
nin = Nsamperframe+2*(M+Ncp);
states.rxbuf(Nrxbuf-nin+1:Nrxbuf) = rx(prx:nin);
prx += nin;

rxbuf_log = []; rxbuf_in_log = []; rx_sym_log = []; foff_hz_log = []; rx_bits_log = [];

states.timing_en = 0;
states.foff_est_en = 1;
states.phase_est_en = 0;

for f=1:Nframes

  % insert samples at end of buffer, set to zero if no samples
  % available to disable phase estimation on future pilots on last
  % frame of simulation
 
  nin = states.nin;
  lnew = min(Nsam-prx+1,nin);
  rxbuf_in = zeros(1,nin);
  %printf("nin: %d prx: %d lnew: %d\n", nin, prx, lnew);
  if lnew
    rxbuf_in(1:lnew) = rx(prx:prx+lnew-1);
  end
  prx += lnew;

  [rx_bits states aphase_est_pilot_log arx_np arx_amp] = ofdm_demod(states, rxbuf_in);

  % log some states for comparison to C

  rxbuf_in_log = [rxbuf_in_log rxbuf_in];
  rxbuf_log = [rxbuf_log states.rxbuf];
  rx_sym_log = [rx_sym_log; states.rx_sym];
  foff_hz_log = [foff_hz_log; states.foff_est_hz];
  rx_bits_log = [rx_bits_log rx_bits];
  
end

% ---------------------------------------------------------------------
% Run C version and plot Octave and C states and differences 
% ---------------------------------------------------------------------

% Override default path by setting path_to_tofdm = "/your/path/to/tofdm"

if exist("path_to_tofdm", "var") == 0
   path_to_tofdm = "../build_linux/unittest/tofdm";
end
system(path_to_tofdm) 

load tofdm_out.txt;

stem_sig_and_error(1, 111, tx_bits_log_c, tx_bits_log - tx_bits_log_c, 'tx bits', [1 length(tx_bits_log) -1.5 1.5])

stem_sig_and_error(2, 211, real(tx_log_c), real(tx_log - tx_log_c), 'tx re', [1 length(tx_log_c) -0.1 0.1])
stem_sig_and_error(2, 212, imag(tx_log_c), imag(tx_log - tx_log_c), 'tx im', [1 length(tx_log_c) -0.1 0.1])

stem_sig_and_error(3, 211, real(rxbuf_in_log_c), real(rxbuf_in_log - rxbuf_in_log_c), 'rxbuf in re', [1 length(rxbuf_in_log_c) -0.1 0.1])
stem_sig_and_error(3, 212, imag(rxbuf_in_log_c), imag(rxbuf_in_log - rxbuf_in_log_c), 'rxbuf in im', [1 length(rxbuf_in_log_c) -0.1 0.1])

stem_sig_and_error(4, 211, real(rxbuf_log_c), real(rxbuf_log - rxbuf_log_c), 'rxbuf re', [1 length(rxbuf_log_c) -0.1 0.1])
stem_sig_and_error(4, 212, imag(rxbuf_log_c), imag(rxbuf_log - rxbuf_log_c), 'rxbuf im', [1 length(rxbuf_log_c) -0.1 0.1])

stem_sig_and_error(5, 211, real(rx_sym_log_c), real(rx_sym_log - rx_sym_log_c), 'rx sym re', [1 length(rx_sym_log_c) -1.5 1.5])
stem_sig_and_error(5, 212, imag(rx_sym_log_c), imag(rx_sym_log - rx_sym_log_c), 'rx sym im', [1 length(rx_sym_log_c) -1.5 1.5])

stem_sig_and_error(6, 111, foff_hz_log_c, (foff_hz_log - foff_hz_log_c), 'foff hz', [1 length(foff_hz_log_c) -1.5 1.5])

stem_sig_and_error(7, 111, rx_bits_log_c, rx_bits_log - rx_bits_log_c, 'rx bits', [1 length(rx_bits_log) -1.5 1.5])

% Run through checklist -----------------------------

check(W, W_c, 'W');
check(tx_bits_log, tx_bits_log_c, 'tx_bits');
check(tx_log, tx_log_c, 'tx');
check(rxbuf_in_log, rxbuf_in_log_c, 'rxbuf in');
check(rxbuf_log, rxbuf_log_c, 'rxbuf');
check(rx_sym_log, rx_sym_log_c, 'rx_sym');
check(foff_hz_log, foff_hz_log_c, 'foff_est_hz');
check(rx_bits_log, rx_bits_log_c, 'rx_bits');