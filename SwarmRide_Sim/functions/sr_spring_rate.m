function ks = sr_spring_rate(TB, m_load)
%SR_SPRING_RATE Secondary spring stiffness per bogie [N/m] at a given load [kg].
%   air    : air spring stiffens in proportion to load (constant bounce frequency)
%   coil   : steel coil springs, constant stiffness (coach sags and softens relatively)
%   casnub : two-stage spring nest, inner springs take part as the wagon is loaded

switch TB.springType
    case 'air'
        ks = TB.ks0 * (TB.m_tare + m_load) / TB.m_tare;
    case 'coil'
        ks = TB.ks0;
    case 'casnub'
        frac = min(m_load / (max(TB.loads_t) * 1e3), 1);
        ks = TB.ks0 + frac * (TB.ks_loaded - TB.ks0);
    otherwise
        error('sr_spring_rate:type', 'Unknown spring type "%s".', TB.springType);
end
end
