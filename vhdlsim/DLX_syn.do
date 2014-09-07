onerror {resume}
quietly WaveActivateNextPane {} 0
vsim -sdftyp /totest/=../syn/results/SYN_DLX.sdf work.tb_dlx_postsyn
source SYN_DLX_wave.do

update
