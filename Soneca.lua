-- SONECA HUB | ROYAL REFINE 9.4 | PROTEGIDO
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
local _packed = {44,162,27,156,126,191,35,194,196,4,202,72,191,213,77,17,239,183,168,176,129,226,153,227,165,155,228,228,171,236,182,121}
local _mask = {212,185,244,86,66,199,117,134,223,88,185,68,147,167,17,80,50,129,7,135,11,4,88,224,136,39,11,163,19,103,135,55}
local _key={}
for i=1,32 do _key[i]=string.char(_x(_packed[i],_mask[((i-1)*7)%32+1])) end
local _nonce = string.char(74,254,209,29,3,100,124,21,109,224,24,95)
local _data = table.concat({
    "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",
    "33s01MYYlyWyHdpkXMiV7dqEHmuiANL/6uk="
})
local _safe, _plain = pcall(function()
    return _lzss(_chacha(table.concat(_key),_nonce,_b64(_data)))
end)
if not _safe then warn("[SONECA] Erro de integridade: "..tostring(_plain));return end
if #_plain ~= 52664 or _adler(_plain) ~= 709352716 then
    warn("[SONECA] Falha de integridade no pacote")
    return
end
local _compile, _err = loadstring(_plain,"=SonecaHubV94_RoyalRefine")
if not _compile then warn("[SONECA] Falha na compilacao: "..tostring(_err));return end
-- Variaveis temporarias locais nao sao expostas ao hub executado.
local _ok, _runtimeError = pcall(_compile)
if not _ok then warn("[SONECA] Erro no hub: "..tostring(_runtimeError)) end
