import {
  ArrowDropDownCircleOutlined,
  FormatListBulleted
} from '@mui/icons-material';

type Props = {
  multiple: boolean;
  fontSize?: 'small' | 'medium';
};

export default function PinPropertyTypeIcon({ multiple, fontSize }: Props) {
  return multiple ? (
    <FormatListBulleted fontSize={fontSize} />
  ) : (
    <ArrowDropDownCircleOutlined fontSize={fontSize} />
  );
}
