-- SONECA HUB | ROYAL PROTECTED 9.3 FIX
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
local _packed = {119,148,7,15,191,39,2,166,219,93,241,31,67,250,224,23,14,74,60,165,217,212,158,181,32,15,58,29,163,31,154,72}
local _mask = {38,46,158,205,68,152,245,110,255,172,17,13,136,60,190,74,232,110,184,218,21,189,127,178,13,249,199,46,1,203,149,44}
local _key={}
for i=1,32 do _key[i]=string.char(_x(_packed[i],_mask[((i-1)*7)%32+1])) end
local _nonce = string.char(21,246,225,139,233,104,203,206,95,169,202,216)
local _data = table.concat({
    "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",
    "ySozTgOqazlyUf1HyIh4"
})
local _safe, _plain = pcall(function()
    return _lzss(_chacha(table.concat(_key),_nonce,_b64(_data)))
end)
if not _safe then warn("[SONECA] Erro de integridade: "..tostring(_plain));return end
if #_plain ~= 49751 or _adler(_plain) ~= 2139419025 then
    warn("[SONECA] Falha de integridade no pacote")
    return
end
local _compile, _err = loadstring(_plain,"=SonecaHubV9_Royal")
if not _compile then warn("[SONECA] Falha na compilacao: "..tostring(_err));return end
-- Variaveis temporarias locais nao sao expostas ao hub executado.
local _ok, _runtimeError = pcall(_compile)
if not _ok then warn("[SONECA] Erro no hub: "..tostring(_runtimeError)) end
