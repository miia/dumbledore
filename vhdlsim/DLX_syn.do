onerror {resume}
quietly WaveActivateNextPane {} 0
vsim -novopt -sdftyp /tb_dlx_postsyn/totest/=../syn/results/SYN_DLX.sdf work.tb_dlx_postsyn -sdfnoerror -t 1fs
source SYN_DLX_wave.do

update
