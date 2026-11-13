-- SONECA HUB | ROYAL PROTECTED 9.1
-- Payload ofuscado: LZ77 + ChaCha20. Apenas para distribuicao autorizada.
-- O carregador inclui o material para decifrar; NAO e uma protecao anticrack absoluta.
-- Compativel com Luau que disponibiliza bit32 e loadstring (Delta).
local _B = bit32
if type(_B) ~= "table" or type(loadstring) ~= "function" then
    warn("[SONECA] Executor sem suporte a bit32 / loadstring")
    return
end
local _x, _rot = _B.bxor, _B.lrotate
local _floor = math.floor
local _mod = 4294967296
local function _wd(s, i)
    local a,b,c,d = s:byte(i,i+3)
    return (a or 0)+(b or 0)*256+(c or 0)*65536+(d or 0)*16777216
end
local function _chacha(key, nonce, message)
    local K={}
    for i=1,32,4 do K[#K+1]=_wd(key,i) end
    local N={_wd(nonce,1),_wd(nonce,5),_wd(nonce,9)}
    local out, pos, counter={},1,1
    while pos <= #message do
        local orig={0x61707865,0x3320646e,0x79622d32,0x6b206574,
            K[1],K[2],K[3],K[4],K[5],K[6],K[7],K[8],counter,N[1],N[2],N[3]}
        local v={}
        for i=1,16 do v[i]=orig[i] end
        local function qr(a,b,c,d)
            v[a]=(v[a]+v[b])%_mod;v[d]=_rot(_x(v[d],v[a]),16)
            v[c]=(v[c]+v[d])%_mod;v[b]=_rot(_x(v[b],v[c]),12)
            v[a]=(v[a]+v[b])%_mod;v[d]=_rot(_x(v[d],v[a]),8)
            v[c]=(v[c]+v[d])%_mod;v[b]=_rot(_x(v[b],v[c]),7)
        end
        for _=1,10 do
            qr(1,5,9,13);qr(2,6,10,14);qr(3,7,11,15);qr(4,8,12,16)
            qr(1,6,11,16);qr(2,7,12,13);qr(3,8,9,14);qr(4,5,10,15)
        end
        local keybytes={}
        for i=1,16 do
            local num=(v[i]+orig[i])%_mod
            keybytes[#keybytes+1]=num%256
            keybytes[#keybytes+1]=_floor(num/256)%256
            keybytes[#keybytes+1]=_floor(num/65536)%256
            keybytes[#keybytes+1]=_floor(num/16777216)%256
        end
        local chunk={}
        for j=1,math.min(64,#message-pos+1) do
            chunk[j]=string.char(_x(message:byte(pos+j-1),keybytes[j]))
        end
        out[#out+1]=table.concat(chunk)
        pos=pos+64;counter=counter+1
    end
    return table.concat(out)
end
local function _b64(s)
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local map={}
    for i=1,#chars do map[chars:byte(i)]=i-1 end
    local out, acc,bits={},0,0
    for i=1,#s do
        local c=map[s:byte(i)]
        if c then
            acc=acc*64+c;bits=bits+6
            if bits>=8 then
                bits=bits-8
                local val=_floor(acc/(2^bits))%256
                out[#out+1]=string.char(val)
                acc=acc%(2^bits)
            end
        end
    end
    return table.concat(out)
end
local function _lzss(s)
    local o, n, i={},0,1
    while i<=#s do
        local tag=s:byte(i);i=i+1
        if tag<128 then
            local ln=tag+1
            for j=i,i+ln-1 do
                n=n+1;o[n]=string.char(s:byte(j))
            end
            i=i+ln
        else
            local ln=tag-128+4
            local l,h=s:byte(i,i+1);i=i+2
            local off=l+h*256
            if off<1 or off>n then error("Pacote Soneca corrompido [ref]") end
            for j=1,ln do
                n=n+1;o[n]=o[n-off]
            end
        end
    end
    return table.concat(o)
end
local function _adler(s)
    local a,b=1,0
    for i=1,#s do
        a=(a+s:byte(i))%65521
        b=(b+a)%65521
    end
    return b*65536+a
end
-- Chave segmentada para evitar reconhecimento trivial em busca de texto.
-- Nao ha segredo persistente em um cliente sem autenticacao externa.
local _packed = {215,121,223,145,41,163,34,10,144,88,160,36,219,200,127,17,122,120,10,94,142,228,183,233,109,183,127,210,130,99,220,247}
local _mask = {121,24,203,18,158,124,0,54,29,202,151,138,203,122,78,33,46,185,18,199,163,80,179,255,28,206,74,18,90,130,48,219}
local _key={}
for i=1,32 do _key[i]=string.char(_x(_packed[i],_mask[((i-1)*7)%32+1])) end
local _nonce = string.char(226,73,182,30,254,251,23,168,137,234,191,205)
local _data = table.concat({
    "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"
})
local _safe, _plain = pcall(function()
    return _lzss(_chacha(table.concat(_key),_nonce,_b64(_data)))
end)
if not _safe then warn("[SONECA] Erro de integridade: "..tostring(_plain));return end
if #_plain ~= 45991 or _adler(_plain) ~= 1576344152 then
    warn("[SONECA] Falha de integridade no pacote")
    return
end
local _compile, _err = loadstring(_plain,"=SonecaHubV9_Royal")
if not _compile then warn("[SONECA] Falha na compilacao: "..tostring(_err));return end
-- Variaveis temporarias locais nao sao expostas ao hub executado.
local _ok, _runtimeError = pcall(_compile)
if not _ok then warn("[SONECA] Erro no hub: "..tostring(_runtimeError)) end
